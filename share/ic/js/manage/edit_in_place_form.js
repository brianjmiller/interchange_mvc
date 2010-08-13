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
    "ic-manage-editinplaceform",
    function(Y) {
        var ManageEIPForm;

        ManageEIPForm = function (config) {
            ManageEIPForm.superclass.constructor.apply(this, arguments);
            this.publish('manageEIPForm:reset', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
        };

        ManageEIPForm.NAME = "ic_manage_editinplaceform";

        Y.extend(
            ManageEIPForm,
            Y.Form,
            {
// reclaiming some whitespace...

    reset: function (bool, e) {
        ManageEIPForm.superclass.reset.apply(this, arguments);
        try {
            e.halt();
        }
        catch (err) {
            Y.log(err);
            Y.log(e);
        }
        this.fire('manageEIPForm:reset');
    }

// ...whitespace returned
            }
        );

        Y.namespace("IC");
        Y.IC.ManageEIPForm = ManageEIPForm;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-form",
            "ic-manage-formfield-date"
        ]
    }
);
