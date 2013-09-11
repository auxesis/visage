/**
 * DeLorean - Flux capacitor for accurately faking time-bound
 * JavaScript unit testing, including timeouts, intervals, and dates
 *
 * version 0.1.2
 *
 * http://michaelmonteleone.net/projects/delorean
 * http://github.com/mmonteleone/delorean
 *
 * Copyright (c) 2009 Michael Monteleone
 * Licensed under terms of the MIT License (README.markdown)
 */
 (function() {

    var global = this;          // capture reference to global scope
    var version = '0.1.2';
    var globalizedApi = false;  // whether or not api has been injected into global scope
    var callbacks = {};         // collection of scheduled functions
    var advancedMs = 0;         // accumulation of total requested ms advancements
    var elapsedMs = 0;          // accumulation of current time as of each callback
    var funcCount = 0;          // number of scheduled functions
    var currentlyAdvancing = false;     // whether or not an advance is in motion
    var executionInterrupted = false;   // whether or not last advance was interrupted

    /**
     * Basic extension helper for copying properties of one object to another
     * @param {Object} dest object to receive properties
     * @param {Object} src object containing properties to copy
     */
    var extend = function(dest, src) {
        for (var prop in src) {
            dest[prop] = src[prop];
        }
    };

    /**
     * Captures references to original values of timing functions
     */
    var originalClock = {
        setTimeout: global.setTimeout,
        setInterval: global.setInterval,
        clearTimeout: global.clearTimeout,
        clearInterval: global.clearInterval,
        Date: global.Date
    };

    /**
     * Extension of standard Date using "parasitic inheritance"
     * http://www.crockford.com/javascript/inheritance.html
     * Intercepts requests to create Date instances of current time
     * and offsets them by the faked time advancement
     * @param {Number} year year
     * @param {Number} month month
     * @param {Number} day day of month
     * @param {Number} hour hour of day
     * @param {Number} minute minute
     * @param {Number} second second
     * @param {Number} millisecond millisecond
     * @returns date
     */
    var ShiftedDate = function(year, month, day, hour, minute, second, millisecond) {
        var shiftedDate;
        if (arguments.length === 0) {
            shiftedDate = new originalClock.Date();
            shiftedDate.setMilliseconds(shiftedDate.getMilliseconds() + effectiveOffset());
        } else if (arguments.length == 1) {
            shiftedDate = new originalClock.Date(arguments[0]);
        } else {
            shiftedDate = new originalClock.Date(
            year || null, month || null, day || null, hour || null,
            minute || null, second || null, millisecond || null);
        }
        return shiftedDate;
    };

    // Keep prototype methods over the facade class
    extend(ShiftedDate, {
        parse: originalClock.Date.parse,
        UTC: originalClock.Date.UTC,
        now: originalClock.Date.now
    });

    /**
     * Resets fake time advancement back to 0,
     * removing all scheduled functions
     */
    var reset = function() {
        callbacks = {};
        funcCount = 0;
        advancedMs = 0;
        currentlyAdvancing = false;
        executionInterrupted = false;
        elapsedMs = 0;
    };

    /**
     * Helper function to return whether a variable is truly numeric
     * @param {Object} value value to test
     * @returns boolean of whether value was numeric
     */
    var isNumeric = function(value) {
        return value !== null && !isNaN(value);
    };

    /**
     * Helper function to return the effective current offset of time
     * from the perspective of executing callbacks
     * @returns milliseconds as Number
     */
    var effectiveOffset = function() {
        return currentlyAdvancing ? elapsedMs: advancedMs;
    };

    /**
     * Advances fake time by an arbitrary quantity of milliseconds,
     * executing all scheduled callbacks that would have occurred within
     * advanced range in proper native order and context
     * @param {Number} ms quantity of milliseconds to advance fake clock
     */
    var advance = function(ms) {
        // advance can optionally accept no parameters
        // for just returning accumulated advanced offset
        if(!!ms) {
            if (!isNumeric(ms) || ms < 0) {
                throw ("'ms' argument must be a positive number");
            }
            // scheduled callbacks to be executed within range
            var schedule = [];
            // build an object to hold time range of this advancement
            var range = {
                start: advancedMs,
                end: advancedMs += ms
            };

            // register an instance of a callback to occur
            // at a particular point in this advance's schedule
            var register = function(fn, at) {
                schedule.push({
                    fn: fn,
                    at: at
                });
            };

            // loop through the scheduleing and execution of callback
            // functions since callbacks could possibly schedule more
            // callbacks of their own (which would interrupt execution)
            do {
                executionInterrupted = false;

                // collect applicable functions to run
                for (var id in callbacks) {
                    var fn = callbacks[id];

                    // schedule all non-repeating timeouts that fall within advvanced range
                    if (!fn.repeats && fn.firstRunAt <= range.end) {
                        register(fn, fn.firstRunAt);
                    // schedule repeating inervals that would fall during the range
                    } else {
                        // schedule instances of first runs of intervals
                        if (fn.lastRunAt === null &&
                            fn.firstRunAt > range.start &&
                            (fn.lastRunAt || fn.firstRunAt) <= range.end) {
                                fn.lastRunAt = fn.firstRunAt;
                                register(fn, fn.lastRunAt);
                        }
                        // add as many instances of interval callbacks as would occur within range
                        while ((fn.lastRunAt || fn.firstRunAt) + fn.ms <= range.end) {
                            fn.lastRunAt += fn.ms;
                            register(fn, fn.lastRunAt);
                        }
                    }
                }

                // sort all the scheduled callback instances to
                // execute in correct browser order
                schedule.sort(function(a, b) {
                    // ORDER BY
                    //   [execution point] ASC,
                    //   [interval length] DESC,
                    //   [order of addition] ASC
                    var order = a.at - b.at;
                    if (order === 0) {
                        order = b.fn.ms - a.fn.ms;
                        if (order === 0) {
                            order = a.fn.id - b.fn.id;
                        }
                    }
                    return order;
                });

                // run scheduled callback instances
                var ran = [];
                for (var i = 0; i < schedule.length; ++i) {
                    var fn = schedule[i].fn;
                    // only run callbacks that are still in master schedule, since a
                    // callback could have been cleared by a subsequent run of anther callback
                    if ( !! callbacks[fn.id]) {
                        elapsedMs = schedule[i].at;
                        // run fn surrounded by a state of
                        // currently advancing
                        currentlyAdvancing = true;
                        try {
                            // run callback function on global context
                            fn.fn.apply(global);
                        } finally {
                            currentlyAdvancing = false;

                            // record this fn instance as having occurred, and thus trashable
                            ran.push(i);

                            // completely trash non-repeating instance
                            // from ever being scheduled again
                            if (!fn.repeats) {
                                removeCallback(fn.id);
                            }

                            // execution could have been interrupted if
                            // a callback had performed some scheduling of its own
                            if (executionInterrupted) {
                                break;
                            }
                        }
                    }
                }
                // remove all run callback instances from schedule
                for (var i = ran.length - 1; i >= 0; i--) {
                    schedule.splice(ran[i], 1);
                }
            }
            while (executionInterrupted);
        }
        return effectiveOffset();
    };

    /**
     * Adds a callback to the master schedule
     * @param {Function} fn callback function
     * @param {Number} ms millisecond at which to schedule callback
     * @returns unique Number id of scheduled callback
     */
    var addCallback = function(fn, ms, repeats) {
        // if scheduled fn was old-school string of code
        // (yes, js officially allows for this)
        if (typeof(fn) == 'string') {
            fn = new Function(fn);
        }
        var at = effectiveOffset();
        var id = funcCount++;
        callbacks[id] = {
            id: id,
            fn: fn,
            ms: ms,
            addedAt: at,
            firstRunAt: (at + ms),
            lastRunAt: null,
            repeats: repeats
        };

        // stop any currently advancing range of fns
        // so that newly scheduled callback can be
        // rolled into advance's schedule (if necessary)
        if (currentlyAdvancing) {
            executionInterrupted = true;
        }

        return id;
    };

    /**
     * Removes a callback from the master schedule
     * @param {Number} id callback identifier
     */
    var removeCallback = function(id) {
        delete callbacks[id];
    };

    /**
     * Gets (and optinally sets) value of whether
     * the native timing functions
     * (setInterval, clearInterval, setTimeout, clearTimeout, Date)
     * should be overwritten by DeLorean's fakes
     * @param {Boolean} shouldOverrideGlobal optional value, when passed, adds or removes the api from global scope
     * @returns {Boolean} true if native API is overwritten, false if not
     */
    var globalApi = function(shouldOverrideGlobal) {
        if (typeof(shouldOverrideGlobal) !== 'undefined') {
            globalizedApi = shouldOverrideGlobal;
            extend(global, globalizedApi ? api: originalClock);
        }
        return globalizedApi;
    };

    /**
     * Faked timing API
     * These are kept in their own object to allow for easy
     * extending and unextending of them from the global scope
     */
    var api = {
        setTimeout: function(fn, ms) {
            // handle exceptional parameters
            if (arguments.length === 0) {
                throw ("Function setTimeout requires at least 1 parameter");
            } else if (arguments.length === 1 && isNumeric(arguments[0])) {
                throw ("useless setTimeout call (missing quotes around argument?)");
            } else if (arguments.length === 1) {
                return addCallback(fn, 0, false);
            }
            // schedule func
            return addCallback(fn, ms, false);
        },
        setInterval: function(fn, ms) {
            // handle exceptional parameters
            if (arguments.length === 0) {
                throw ("Function setInterval requires at least 1 parameter");
            } else if (arguments.length === 1 && isNumeric(arguments[0])) {
                throw ("useless setTimeout call (missing quotes around argument?)");
            } else if (arguments.length === 1) {
                return addCallback(fn, 0, false);
            }
            // schedule func
            return addCallback(fn, ms, true);
        },
        clearTimeout: removeCallback,
        clearInterval: removeCallback,
        Date: ShiftedDate
    };

    // expose a public api containing DeLorean utility methods
    global.DeLorean = {
        reset: reset,
        advance: advance,
        globalApi: globalApi,
        version: version
    };
    // extend public API with the timing methods
    extend(global.DeLorean, api);

    // set the initial state
    reset();
})();
