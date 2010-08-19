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
    "ic-manage-formfield-datetime",
    function(Y) {
        var DateTimeField;

        DateTimeField = function (config) {
            DateTimeField.superclass.constructor.apply(this, arguments);
        }

        DateTimeField.NAME = 'ic_manage_formfield_datetime';

        Y.extend (
            DateTimeField, 
            Y.IC.DateField,
            {
// recovering some whitespace...

    bindUI: function () {
        /**
         * Accessing the _time private var here is required (as of 2010-08-18)
         * to pre-set a specific time in the calendar widget, even if the date
         * object has hh:mm:ss.  This is a bug waiting to happen if the 
         * gallery-calendar module gets refactored and added to the YUI CDN.
         **/
        this._calendar._time = this._calendar.date;
        this._calendar.render();
        this._calendar.on('timeselect', Y.bind(function (d) {
            this._setValue(d);
        }, this));
        this._fieldNode.on('focus', Y.bind(function () {
            this._calendar.show();
        }, this));
    },

    _setValue: function (d) {
        // Y.log('datetime::_setValue');
        var date_str;
        date_str = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' +
            d.getDate() + 'T' + d.getHours() + ':' + d.getMinutes() +
            ':' + d.getSeconds();
        this._fieldNode.set('value', date_str);
        this._calendar.hide();
    },

    _massageConfig: function (config) {
        config.withtime = true;
    }
                
// ...whitespace returned
            }
        );

        Y.namespace("IC");
        Y.IC.DateTimeField = DateTimeField;

    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-formfield-date"
        ]
    }
);

