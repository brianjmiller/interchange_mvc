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

/*
    this is basically just a stubbed in class that allows to instantiate
    a basic AutoComplete object that can then be used to attach event handlers
    to, etc. for when AutoCompleteList isn't desired

    Hopefully this can be removed soon, see AC enhancement request:
        http://yuilibrary.com/projects/yui3/ticket/2529854
*/
YUI.add(
    "ic-autocomplete",
    function(Y) {
        var Clazz = Y.namespace("IC").AutoComplete = Y.Base.create(
            "custom_autocomplete",
            Y.Base,
            [ Y.AutoCompleteBase ],
            {
                initializer: function (config) {
                    //Y.log(Clazz.NAME + "::initializer");
                    this._bindUIACBase();
                    this._syncUIACBase();
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
            "autocomplete-base",
            "autocomplete-sources"
        ]
    }
);
