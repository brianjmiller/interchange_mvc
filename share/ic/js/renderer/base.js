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
    "ic-renderer-base",
    function(Y) {
        var Clazz = Y.namespace("IC").RendererBase = Y.Base.create(
            "ic_renderer_base",
            Y.Widget,
            [ Y.WidgetChild ],
            {},
            {
                ATTRS: {
                    advisory_width: {
                        value: null
                    },
                    advisory_height: {
                        value: null
                    }
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-base-css",
            "widget"
        ]
    }
);
