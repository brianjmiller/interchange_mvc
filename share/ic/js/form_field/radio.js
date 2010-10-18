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
    "ic-formfield-radio",
    function(Y) {
        var Field;

        Field = function (config) {
            Field.superclass.constructor.apply(this, arguments);
        }

        Y.mix(
            Field,
            {
                NAME: 'ic_formfield_radio',
                ATTRS: {
                    multiple: {
                        value: false
                    }
                }
            }
        );

        Y.extend (
            Field, 
            Y.ChoiceField,
            {
                _renderFieldNode : function () {
                    var contentBox = this.get('contentBox'),
                        choices = this.get('choices');
       
                    Y.Array.each(choices, function(c, i, a) {
                        var cfg = {
                            value : c.value,
                            id : (this.get('id') + '_choice' + i),
                            name : this.get('name'),
                            label : c.label,

                            // my change to allow pre-checking of node
                            checked: c.checked
                            // end my change
                        },
                        fieldType = (this.get('multiple') === true ? Y.CheckboxField : Y.RadioField),
                        field = new fieldType(cfg);

                        field.render(contentBox);
                    }, this);

                    this._fieldNode = contentBox.all('input');
                }
            }
        );

        Y.namespace("IC.FormField");
        Y.IC.FormField.Radio = Field;
    },
    "@VERSION@",
    {
        requires: [
            "gallery-form"
        ]
    }
);

