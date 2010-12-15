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
    "ic-manage-window-content-remote-function",
    function (Y) {
        var Clazz = Y.namespace("IC").ManageWindowContentRemoteFunction = Y.Base.create(
            "ic_manage_window_content_remote_function",
            Y.IC.ManageWindowContentRemote,
            [],
            {
                initializer: function (config) {
                    Y.log(Clazz.NAME + "::initializer");

                    this._data_url = "/manage/" + config.clazz + "/ui_meta_struct?_format=json";
                    Y.log(Clazz.NAME + "::initializer - _data_url: " + this._data_url);
                }
            },
            {
                ATTRS: {},

                getCacheKey: function (config) {
                    Y.log(Clazz.NAME + "::getCacheKey");
                    return "remote-function-" + config.clazz;
                }
            }
        );
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-content-remote-function-css",
            "ic-manage-window-content-remote"
        ]
    }
);
