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
    "ic-manage-widget",
    function(Y) {

        var ManageWidget = Y.Base.create (
            "ic_manage_widget",       // module identifier  
            Y.Widget,                 // what to extend     
            [                         // classes to mix in  
                Y.IC.HistoryManager
            ],
            {}                        // overrides/additions
        );

        Y.namespace("IC");
        Y.IC.ManageWidget = ManageWidget;
    },
    "@VERSION@",
    {
        requires: [
            "ic-history-manager",
            "base-base",
            "widget"
        ]
    }
);


