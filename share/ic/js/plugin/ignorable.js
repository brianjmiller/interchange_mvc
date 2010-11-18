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
    "ic-plugin-ignorable",
    function(Y) {
        var Ignorable;

        Ignorable = function (config) {
            Ignorable.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            Ignorable,
            {
                NS:    'ignorable',
                NAME:  'ic_plugin_ignorable',
                ATTRS: {
                }
            }
        );

        Y.extend (
            Ignorable,
            Y.Plugin.Base,
            {
                _host: null,
                _timer: null,

                initializer: function (config) {
                    Y.log(Ignorable.NAME + "::initializer");

                    this._host = this.get('host');
                    Y.log(Ignorable.NAME + "::initializer: " + Y.dump(this._host));

                    var button = new Y.Button (
                        {
                            label:  config.label || 'Ignore',
                            render: this._host
                        }
                    );
                    button.set(
                        'callback',
                        Y.bind(
                            function () {
                                Y.log(Ignorable.NAME + ' button callback');

                                this.schedule_destroy();
                            },
                            this
                        )
                    );

                    this._bindUI();
                }, 

                schedule_destroy: function () {
                    Y.log(Ignorable.NAME + "::schedule_destroy");

                    this._host.setContent('This space intentionally left blank.');

                    this._timer = Y.later(
                        3000,
                        this,
                        function() {
                            this._host.addClass('hide');
                            this._host.destroy();
                        },
                        null,
                        false
                    );
                },

                destructor: function (el) {
                    Y.log(Ignorable.NAME + "::destructor" + (el ? el : ''));

                    this._detachUI();
                },

                _bindUI: function () {
                    Y.log(Ignorable.NAME + "::_bindUI");
                },

                _detachUI: function () {
                    Y.log(Ignorable.NAME + "::_detachUI");
                }
            }
        );

        Y.namespace("IC.Plugin");
        Y.IC.Plugin.Ignorable = Ignorable;
    },
    "@VERSION@",
    {
        requires: [
            "ic-plugin-ignorable-css",
            "plugin",
            "gallery-button"
        ]
    }
);
