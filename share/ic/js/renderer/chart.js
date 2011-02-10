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
    "ic-renderer-chart",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererChart = Y.Base.create(
            "ic_renderer_chart",
            Y.IC.RendererBase,
            [],
            {
                _chart: null,

                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");
                    //Y.log(Clazz.NAME + "::initializer - config: " + Y.dump(config));
                    var chart_args = {
                        dataProvider: config.chart_config.data,
                        width:        500,
                        height:       250,
                        axes:         {
                            order_counts: {
                                type:           "numeric",
                                position:       "left",
                                keys:           [ "count" ],
                                roundMinAndMax: true,
                                roundingUnit:   5
                            },
                            days: {
                                type:     "category",
                                position: "bottom",
                                styles:   {
                                    label: {
                                        rotation: -63
                                    }
                                }
                            }
                        }
                    };
                    //if (config.caption) {
                        //chart_args.caption = config.caption;
                    //}
                    //Y.log(Clazz.NAME + "::initializer - chart_args: " + Y.dump(chart_args));

                    this._chart = new Y.Chart (chart_args);
                },

                destructor: function () {
                    Y.log(Clazz.NAME + "::destructor");

                    this._chart = null;
                },

                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    Clazz.superclass.renderUI.apply(this, arguments);

                    this._chart.render(this.get("contentBox"));
                }
            }
        );

        Y.IC.Renderer.registerConstructor("Chart", Clazz.prototype.constructor);
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-chart-css",
            "ic-renderer-base",
            "charts"
        ]
    }
);
