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
        var RendererChart;

        RendererChart = function (config) {
            RendererChart.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            RendererChart,
            {
                NAME: "ic_renderer_chart",
                ATTRS: {
                }
            }
        );

        Y.extend(
            RendererChart,
            Y.IC.RendererBase,
            {
                _chart: null,

                initializer: function (config) {
                    Y.log("renderer_chart::initializer");
                    Y.log("renderer_chart::initializer - config: " + Y.dump(config));
                    var chart_args = {
                        dataProvider: config.data
                    };
                    //if (config.caption) {
                        //chart_args.caption = config.caption;
                    //}
                    Y.log("renderer_chart::initializer - chart_args: " + Y.dump(chart_args));

                    this._chart = new Y.Chart (chart_args);
                },

                renderUI: function () {
                    Y.log("renderer_chart::renderUI");
                    Y.log("renderer_chart::renderUI - contentBox: " + this.get("contentBox"));

                    this._chart.render(this.get("contentBox"));
                },

                bindUI: function () {
                    Y.log("renderer_chart::bindUI");
                },

                syncUI: function () {
                    Y.log("renderer_chart::syncUI");
                },
            }
        );

        Y.namespace("IC");
        Y.IC.RendererChart = RendererChart;
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base",
            "gallery-chart"
        ]
    }
);
