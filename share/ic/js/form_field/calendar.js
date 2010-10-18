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
    "ic-formfield-calendar",
    function(Y) {
        var Field;

        Field = function (config) {
            Field.superclass.constructor.apply(this, arguments);
        }

        Y.mix(
            Field,
            {
                NAME: 'ic_formfield_calendar',
                ATTRS: {}
            }
        );

        Y.extend (
            Field, 
            Y.TextField,
            {
                _calendar: null,

                renderUI: function() {
                    Y.log("formfield_calendar::renderUI");

                    var cid           = Y.guid();
                    var calendar_node = Y.Node.create('<div id="' + cid + '"></div>');

                    this.get("contentBox").append(calendar_node);

                    var config = this._getConfigFromValue();
                    this._massageConfig(config);

                    this._calendar = new Y.Calendar (
                        cid,
                        config
                    );
                    Field.superclass.renderUI.apply(this, arguments);
                },

                bindUI: function () {
                    Y.log("formfield_calendar::bindUI");
                    this._calendar.on(
                        'select',
                        Y.bind(
                            function (d) {
                                this._setValue(d);
                            },
                            this
                        )
                    );
                    this._fieldNode.on(
                        'focus',
                        Y.bind(
                            function () {
                                this._calendar.show();
                            },
                            this
                        )
                    );
                },

                _setValue: function (d) {
                    Y.log('formfield_calendar::_setValue');
                    var date_str = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();

                    this._fieldNode.set('value', date_str);
                },

                _getConfigFromValue: function () {
                    // 2009-11-30T11:01:00
                    var matches = this.get('value').match(/(\d{4})-(\d{2})-(\d{2})(T(\d{2}):(\d{2}):(\d{2}))?/);

                    var date;
                    var withtime;
                    if (matches) {
                        var year     = matches[1];
                        var month    = matches[2];
                        var day      = matches[3];

                        withtime = matches[4] ? true : false;
                        var hours;
                        var mins;
                        var secs;
                        if (withtime) {
                            hours = matches[5];
                            mins  = matches[6];
                            secs  = matches[7];
                        }
                        else {
                            hours = mins = secs = '00';
                        }

                        date = new Date (
                            year,
                            month-1,
                            day,
                            hours,
                            mins,
                            secs
                        );
                    }
                    else {
                        date = new Date ();
                    }

                    return { withtime: withtime, date: date }
                },

                _massageConfig: function (config) {
                    config.withtime = false;
                }
            }
        );

        Y.namespace("IC.FormField");
        Y.IC.FormField.Calendar = Field;
    },
    "@VERSION@",
    {
        requires: [
            "gallery-form",
            "gallery-calendar"
        ]
    }
);

