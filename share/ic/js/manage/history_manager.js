/*
    Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
       
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see: http://www.gnu.org/licenses/ 
*/

YUI.add(
    "ic-history-manager",
    function(Y) {
        var HistoryManager;

        HistoryManager = function () {
            // empty constructor - this is a mixin
        };

        HistoryManager.ATTRS = {
            visible: {
                value: true
            },
            prefix: {        // a prefix for history state variables 
                value: null  //  to distinguish this object from its siblings
            },
            state: {         // my state, used by history to drive my content
                value: null,
                setter: function(new_state) {
                    var old_state = this.get('state'); //Y.HistoryLite.get();
                    var sp = this.STATE_PROPERTIES;

                    // useful debug for a specific object
                    /*
                    if (this.get('prefix') === '_ls') {
                        Y.log('sp -> old_state -> new_state :: prefix = ' + this.get('prefix'));
                        Y.log(sp);
                        Y.log(Y.merge(old_state));
                        Y.log(Y.merge(new_state));
                    }
                    */

                    // wipe out all the prior state properties to start fresh
                    Y.each(old_state, function (v, k, obj) {
                        if (sp[k]) {
                            obj[k] = null;
                        }
                    });

                    // only allow our STATE_PROPERTIES, no others
                    Y.each(new_state, function (v, k, obj) {
                        if (!sp[k]) {
                            delete obj[k];
                        }
                        // convert any numbers to strings
                        obj[k] = obj[k] + '';
                    });

                    var m = Y.merge(old_state, new_state);
                    return m;
                }
            }
        };

        HistoryManager.prototype = {

            STATE_PROPERTIES: {},
            _on_history_change: null,

            hide: function () {
                // Y.log('widget::hide - prefix: ' + this.get('prefix'));
                var sp = this.STATE_PROPERTIES;
                var keys = Y.Object.keys(this._addMyHistoryPrefix(sp));
                this.clearHistoryOf(keys);
                if (this._on_history_change) {
                    this._on_history_change.detach();
                    this._on_history_change = null;
                }
                return this.set('visible', false);
            },

            show: function () {
                // Y.log('widget::show - prefix: ' + this.get('prefix'));
                if (!this._on_history_change) {
                    this._on_history_change = Y.on(
                        'history-lite:change', 
                        Y.bind(this._onHistoryChange, this)
                    );
                }
                var state = this.get('state');
                Y.IC.ManageHistory.updateHistory(this);
                /*
                var new_hist = this._addMyHistoryPrefix(state);
                Y.HistoryLite.add(new_hist);
                */
                return this.set('visible', true);
            },

            areEqualObjects: function (a, b) {
                // Y.log('history_manager::areEqualObjects');
                if (typeof(a) != typeof(b)) {
                    return false;
                }
                var allkeys = {};
                for (var j in a) {
                    allkeys[j] = 1;
                }
                for (var k in b) {
                    allkeys[k] = 1;
                }
                for (var i in allkeys) {
                    if (a.hasOwnProperty(i) != b.hasOwnProperty(i)) {
                        if ((a.hasOwnProperty(i) && Y.Lang.isFunction(b[i])) ||
                            (a.hasOwnProperty(i) && Y.Lang.isFunction(b[i]))) {
                            continue;
                        } else {
                            // Y.log('failed on missing property');
                            return false;
                        }
                    }
                    if (typeof(a[i]) !== typeof(b[i])) {
                        // Y.log('failed on matching types');
                        return false;
                    }
                    if (Y.Lang.isObject(a[i])) {
                        if (!this.areEqualObjects(a[i], b[i])) {
                            return false;
                        }
                    } else {
                        if (a[i] !== b[i]) {
                            // Y.log('failed on matching values');
                            return false;
                        }
                    }
                }
                return true;
            },

            /*
             * Gets the history, and returns an object with only the
             * STATE_PROPERTIES that are set in history data.
             */
            getRelaventHistory: function () {
                // Y.log('history_manager::getRelaventHistory - prefix:' + this.get('prefix'));
                var rh = {}; // relavent history
                var sp = this.STATE_PROPERTIES;
                var prefix = this.get('prefix');
                var history = Y.HistoryLite.get();
                Y.each(sp, function (v, k, obj) {
                    var pfk = prefix + k;
                    if (!Y.Lang.isUndefined(history[pfk])) {
                        // sometimes this history is out-dated,
                        //  so check for null values in the hqueue
                        if (Y.IC.ManageHistory.hqueue[pfk] !== null) {
                            rh[k] = history[pfk];
                        }
                    }
                });
                return rh;
            },

            stateMatchesHistory: function () {
                var state = this.get('state');
                // first check to ensure state has been initialized
                if (!Y.Lang.isObject(state)) {
                    return false;
                }
                var rh = this.getRelaventHistory();
                return this.areEqualObjects(state, rh);
            },

            clearHistoryOf: function (keys) {
                // Y.log('history_manager::clearHistoryOf');
                if (Y.Lang.isString(keys)) {
                    keys = [keys];
                }
                var saved_state = Y.merge(this.get('state'));
                var clear = {};
                Y.each(keys, function (v, i, ary) {
                    clear[v] = null;
                });
                Y.IC.ManageHistory.clearHistory(clear);
            },

            _addMyHistoryPrefix: function (o) {
                var copy = Y.merge(o);
                var prefix = this.get('prefix');
                var hp = this.STATE_PROPERTIES;
                Y.each(copy, function (v, k, obj) {
                    // verify that it isn't already prefixed
                    if (k.indexOf(prefix) !== 0) {
                        // only modify my history properties
                        if (hp[k]) {
                            delete obj[k];
                            obj[prefix + k] = v;
                        }
                    }
                });
                return copy;
            },

            _stripMyHistoryPrefix: function (o) {
                var copy = Y.merge(o);
                var prefix = this.get('prefix');
                var hp = this.STATE_PROPERTIES;
                Y.each(copy, function (v, k, obj) {
                    // continue if not prefixed
                    if (k.indexOf(prefix) === 0) {
                        // only modify my history properties
                        if (hp[k]) {
                            delete obj[k];
                            obj[k.substring(prefix.length)] = v;
                        }
                    }
                });
                return copy;
            },

            _notifyHistory: function () {
                // Y.log('history_manager::_notifyHistory - prefix -> state');
                // Y.log(this.get('prefix'));
                // Y.log(this.get('state'));
                if (!this.stateMatchesHistory()) {
                    try {
                        Y.IC.ManageHistory.updateHistory(this);
                    } catch (err) {
                        Y.log(err);
                    }
                }
            },

            _onHistoryChange: function (e) {
                // Y.log('history_manager::_onHistoryChange - prefix: ' + this.get('prefix'));
                if ( ! this.stateMatchesHistory() ) {
                    /*
                    Y.log('_onHistoryChange - state does not match history ... state -> history');
                    Y.log(Y.merge(this.get('state')));
                    Y.log(Y.merge(this.getRelaventHistory()));
                    */
                    this.set('state', this.getRelaventHistory());
                }
            }
        };

        Y.namespace("IC");
        Y.IC.HistoryManager = HistoryManager;
    },
    "@VERSION@",
    {
        requires: [
            "gallery-history-lite",
            "ic-manage-history",
            "widget"
        ]
    }
);
    
