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
    "ic-manage-window-tools-your_links",
    function(Y) {
        var Clazz = Y.namespace("IC.ManageTool").YourLinks = Y.Base.create(
            "ic_manage_tools_your_links",
            Y.IC.ManageTool.Base,
            [],
            {
                renderUI: function () {
                    Y.log(Clazz.NAME + "::renderUI");
                    this.get("contentBox").setContent( Clazz.NAME );
                }
            },
            {
                ATTRS: {}
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-tools-your_links-css",
            "ic-manage-window-tools-base"
        ]
    }
);
