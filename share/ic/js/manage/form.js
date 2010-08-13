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
    "ic-manage-form",
    function(Y) {
        var ManageForm;

        ManageForm = function (config) {
            ManageForm.superclass.constructor.apply(this, arguments);
        };

        ManageForm.NAME = "ic_manage_form";

        Y.extend(
            ManageForm,
            Y.Form,
            {
// reclaiming some whitespace...

                /*
                  Was considering overriding the _renderFormFields so
                  that hidden fields whould be rendered as static text
                  nodes with hidden form fields (so the values appear
                  but are not editable.

                  But I think a better solution is to provide custom
                  FormFields, such as a HiddenDisabled, or
                  UneditableText.
                 */
// ...whitespace returned
            }
        );

        Y.namespace("IC");
        Y.IC.ManageForm = ManageForm;
    },
    "@VERSION@",
    {
        requires: [
            "gallery-form"
        ]
    }
);
