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
    "ic-manage-history",
    function (Y) {

        var ManageHistory = function (config) {
            ManageHistory.superclass.constructor.apply(this, arguments);
            Y.Global.publish('ic_manage_history:update', {
                broadcast:  2,   // global notification
                emitFacade: true // emit a facade so we get the event target
            });
            Y.Global.publish('ic_manage_history:clear', {
                broadcast:  2,   // global notification
                emitFacade: true // emit a facade so we get the event target
            });
        };
 
        ManageHistory.NAME = "ic_manage_history";
 
        Y.extend(ManageHistory, Y.Base, {

            hqueue: {},    // not really a queue... 
                           //  keeps track of what needs to be in the 
                           //  next history update

            // might be cleaner to get the STATE_PROPERTIES from each
            // object expected in a profile...
            profiles: [
                {
                    _mwlc: 'dash'
                },
                {
                    _mwlc: 'dtmax', 
                    _dtkind: 'function', _dtsub_kind: 'list', _dtargs: true,
                    _lsresults: true, _lsstartIndex: true, _lssort: true, _lsdir: true, _lssrec: '-1'
                },
                {
                    _mwlc: 'dtdv', 
                    _dtkind: 'function', _dtsub_kind: 'list', _dtargs: true,
                    _lsresults: true, _lsstartIndex: true, _lssort: true, _lsdir: true, _lssrec: true,
                    _dvkind: 'function', _dvsub_kind: 'detail', _dvargs: true,
                    _dx_otst: true
                }
            ],

            initializer : function (cfg) {
                Y.Global.on(
                    'ic_manage_history:update', 
                    Y.bind(this.onUpdateHistory, this)
                );
                Y.Global.on(
                    'ic_manage_history:clear', 
                    Y.bind(this.onClearHistory, this)
                );
            },

            enqueueState: function (obj, state) {
                // Y.log('history:enqueueState - hqueue');
                if (!state)
                    state = obj.get('state');

                // push a prefixed version of the state onto the queue
                var prefixed = obj._addMyHistoryPrefix(state);
                this.hqueue = Y.merge(this.hqueue, prefixed);
                // Y.log(Y.merge(this.hqueue));
            },

            dequeueState: function (obj) {
                // Y.log('history:dequeueState - hqueue');
                this.hqueue = Y.merge(this.hqueue, obj);
                // Y.log(Y.merge(this.hqueue));
            },

            checkCompleteness: function (history) {
                // Y.log('history:checkCompleteness - hqueue');
                // Y.log(this.hqueue);

                if (!history) 
                    history = Y.HistoryLite.get();

                // if the layout becomes less complex, clear the history
                if (this.hqueue._mwlc &&
                    this.hqueue._mwlc !== history._mwlc &&
                    (history._mwlc === 'dtdv' ||
                     (history._mwlc === 'dtmax' && 
                      this.hqueue._mwlc === 'dash'))) {
                    history = {};
                }
                // otherwise, merge the history with the queue (we're building)
                var states = Y.merge(history, this.hqueue);
                
                // run through each of our profiles
                var test;
                Y.some(this.profiles, function (profile) {
                    test = false;
                    // first test the sizes (have to account for cleared states)
                    var states_size = 0;
                    Y.each(states, function (v) {
                        if (v !== null) states_size++;
                    });
                    if (Y.Object.size(profile) !== states_size) {
                        // Y.log('number of keys do not match - failure');
                        test = false;
                    }
                    else {
                        Y.some(profile, function (v, k) {
                            // a "specific value" test
                            if (v !== true && v === states[k]) {
                                test = true;
                            }
                            // a "value exists" test
                            else if (v === true && Y.Lang.isValue(states[k])) {
                                test = true;
                            }
                            else {
                                // Y.log('failed on: profile.' + k + ' = ' + v +
                                //       ' states.' + k + ' = ' + states[k]);
                                test = false;
                                return true; // break out of the loop
                            }
                        });
                    }
                    if (test) {
                        // i passed that profile, so get out of here
                        // Y.log('passed profile:');
                        // Y.log(profile);
                        return true;
                    }
                });

                if (test) {
                    // Y.log('passed completeness check');
                    return states;
                }
                else {
                    // Y.log('failed completeness check');
                    return false;
                }
            },

            setHistory: function (old_history, new_history) {
                // Y.log('history:setHistory -  merged hqueue');
                if (!old_history) {
                    old_history = Y.HistoryLite.get();
                }

                if (!new_history) {
                    // merge the old history with the hqueue
                    new_history = Y.merge(old_history, hqueue);
                }
                else {
                    // null out any unrequired history
                    Y.each(old_history, function (v, k, obj) {
                        obj[k] = null;
                    });
                    new_history = Y.merge(old_history, new_history);
                }

                // clear the queue
                this.hqueue = {};

                // write a new history entry
                // Y.log(new_history);
                Y.HistoryLite.add(new_history);
            },

            getEventObject: function (e) {
                // sometimes I get e.details, othertimes e is the obj...
                var obj;
                try {
                    obj = e.details[0];
                } catch (err) {
                    if (Y.Lang.isFunction(e.get)) 
                        obj = e;
                }

                return obj;
            },

            onUpdateHistory: function (e) {
                // Y.log('history:onUpdateHistory e');
                // Y.log(e);

                // if i don't stop event propagation, it continues forever.
                if (Y.Lang.isFunction(e.stopPropagation))
                    e.stopPropagation();

                var obj = this.getEventObject(e);
                if (obj) {
                    var state = obj.get('state');
                    var history = Y.HistoryLite.get();
                    /*
                    Y.log('state -> history -> hqueue');
                    Y.log(Y.merge(state));
                    Y.log(Y.merge(history));
                    Y.log(Y.merge(this.hqueue));
                    */
                    this.enqueueState(obj, state);
                    var states = this.checkCompleteness(history);
                    if (states) {
                        this.setHistory(history, states);
                    }
                }
            },

            onClearHistory: function (e) {
                // Y.log('history:onClearHistory - e');
                // Y.log(e);

                if (Y.Lang.isFunction(e.stopPropagation))
                    e.stopPropagation();

                var obj = this.getEventObject(e);
                if (obj && Y.Object.size(obj) > 0) {
                    // add each item in the object to the clear queue
                    this.dequeueState(obj);
                }
            }
        });

        Y.namespace("IC");
        Y.IC.ManageHistory = ManageHistory;
    },
    "@VERSION@",
    {
        requires: [
            "base-base",
            "gallery-history-lite",
            "event-custom"
        ]
    }
);
