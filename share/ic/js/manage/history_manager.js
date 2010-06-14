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
            // empty constructor
        };

        HistoryManager.ATTRS = {
            prefix: {        // a prefix for history state variables 
                value: null  //  to distinguish this object from its siblings
            },
            state: {         // my state, used by history to drive my content
                value: null,
                setter: function(new_state) {
                    var old_state = Y.HistoryLite.get();
                    var sp = this.STATE_PROPERTIES;
                    // we wipe out all the prior state properties to start fresh
                    Y.each(old_state, function (v, k, obj) {
                        if (sp[k]) {
                            obj[k] = null;
                        }
                    });
                    // we only allow our STATE_PROPERTIES, no others
                    Y.each(new_state, function (v, k, obj) {
                        if (!sp[k]) {
                            delete obj[k];
                        }
                    });
                    return Y.merge(old_state, new_state);
                }
            }
        };

        HistoryManager.prototype = {
            STATE_PROPERTIES: {},

            isEmpty: function (obj) {
                for(var i in obj) { 
                    return false; 
                } 
                return true;
            },

            areEqualObjects: function (a, b) {
                if (typeof(a) != typeof(b)) {
                    return false;
                }
                var allkeys = {};
                for (var i in a) {
                    allkeys[i] = 1;
                }
                for (var i in b) {
                    allkeys[i] = 1;
                }
                for (var i in allkeys) {
                    if (a.hasOwnProperty(i) != b.hasOwnProperty(i)) {
                        if ((a.hasOwnProperty(i) && typeof(b[i]) == 'function') ||
                            (a.hasOwnProperty(i) && typeof(b[i]) == 'function')) {
                            continue;
                        } else {
                            return false;
                        }
                    }
                    if (typeof(a[i]) != typeof(b[i])) {
                        return false;
                    }
                    if (typeof(a[i]) == 'object') {
                        if (!this.areEqualObjects(a[i], b[i])) {
                            return false;
                        }
                    } else {
                        if (a[i] !== b[i]) {
                            return false;
                        }
                    }
                }
                return true;
            },

            getRelaventHistory: function () {
                var sp = this.STATE_PROPERTIES;
                var prefix = this.get('prefix');
                var history = Y.HistoryLite.get();
                var rh = {}; // relavent history
                Y.each(sp, function (v, k, obj) {
                    if (typeof history[prefix + k] !== undefined) {
                        rh[k] = history[prefix + k];
                    }
                });
                return rh;
            },

            stateMatchesHistory: function () {
                var state = this.get('state');
                // first check to ensure state has been initialized
                if (typeof(state) != 'object') {
                    return false;
                }
                var rh = this.getRelaventHistory();
                return this.areEqualObjects(state, rh);
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

            _onHistoryChange: function (e) {
                // Y.log('_onHistoryChange');
                if ( ! this.stateMatchesHistory() ) {
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
            "widget"
        ]
    }
);
    
