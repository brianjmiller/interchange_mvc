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
    "ic-renderer",
    function(Y) {
        Y.namespace("IC.Renderer");

        //
        // renderers register themselves with us, which populates
        // the below mapping to be used when getting a constructor
        // for a given renderer
        //
        var _constructor_map = {};

        var _control_template_map = {
            TextField:     '<input />',
            HiddenField:   '<input type="hidden" />',
            CheckboxField: '<input type="checkbox" />',
            TextareaField: '<textarea></textarea>',
            SelectField:   '<select></select>',
            Button:        '<button></button>'
        };

        Y.IC.Renderer.registerConstructor = function (key, func) {
            Y.log("Y.IC.Renderer::registerConstructor");
            Y.log("Y.IC.Renderer::registerConstructor - key: " + key);

            if (Y.Lang.isValue(_constructor_map[key])) {
                Y.log("Y.IC.Renderer::registerConstructor - constructor already registered: " + key, "warn");
            }

            _constructor_map[key] = func;
        };

        Y.IC.Renderer.getConstructor = function (key) {
            Y.log("Y.IC.Renderer::getConstructor");
            Y.log("Y.IC.Renderer::getConstructor - key: " + key);

            return _constructor_map[key];
        };

        Y.IC.Renderer.buildContent = function (config) {
            Y.log("Y.IC.Renderer::buildContent");
            Y.log("Y.IC.Renderer::buildContent - render: " + config.render);
            //Y.log("Y.IC.Renderer::buildContent - config: " + Y.dump(config));
            var content_node = config.render || Y.Node.create('<div class="ic-renderer-content_node"></div>');

            if (Y.Lang.isString(config)) {
                // the simple case, what they passed is our content
                Y.log("Y.IC.Renderer::buildContent - string");
                content_node.setContent(config);
            }
            else if (Y.Lang.isArray(config)) {
                Y.log("Y.IC.Renderer::buildContent - array");
                Y.each(
                    config,
                    function (v, i, a) {
                        if (Y.Lang.isString(v)) {
                            this.append(Y.IC.Renderer.buildContent(v));
                        }
                        else {
                            if (! Y.Lang.isValue(v.render)) {
                                v.render = this;
                            }
                            Y.IC.Renderer.buildContent(v);
                        }
                    },
                    content_node
                );
            }
            else {
                if (Y.Lang.isValue(config.type)) {
                    Y.log("Y.IC.Renderer::buildContent - type: " + config.type);
                    var content_constructor = Y.IC.Renderer.getConstructor(config.type);

                    if (! Y.Lang.isValue(config.config.render)) {
                        config.config.render = content_node;
                    }

                    return new content_constructor (config.config);
                }
                else if (Y.Lang.isArray(config.controls)) {
                    Y.log("Y.IC.Renderer::buildContent - controls: " + Y.dump(config.controls));
                    Y.each(
                        config.controls,
                        function (control, i, a) {
                            if (Y.Lang.isValue(control.pre_label)) {
                                var label_node = Y.Node.create('<label>' + control.pre_label + '</label>');

                                content_node.append(label_node);
                            }

                            var control_node = Y.Node.create(_control_template_map[control.type]);
                            if (Y.Lang.isValue(control.clazz)) {
                                control_node.addClass(control.clazz);
                            }

                            if (Y.Lang.isValue(control.name)) {
                                control_node.setAttribute("name", control.name);
                            }

                            if (Y.Lang.isValue(control.value)) {
                                if (control.type === "TextareaField" || control.type === "Button") {
                                    control_node.setContent(control.value);
                                }
                                else {
                                    control_node.setAttribute("value", control.value);
                                }
                            }
                            if (Y.Lang.isArray(control.choices)) {
                                if (control.type === "SelectField") {
                                    Y.each(
                                        control.choices,
                                        function (option, ii, ia) {
                                            control_node.append('<option value="' + option.value + '"' + (option.selected ? ' selected="selected"' : '') + '>' + (Y.Lang.isValue(option.label) ? option.label : option.value) + '</option>');
                                        }
                                    );
                                }
                            }
                            if (Y.Lang.isValue(control.checked) && control.checked) {
                                control_node.setAttribute("checked", "checked");
                            }

                            content_node.append(control_node);
                        }
                    );
                }
                else {
                    Y.log("Y.IC.Renderer::buildContent - unrecognized configuration: " + Y.dump(config));
                }
            }

            return content_node;
        };
    },
    "@VERSION@",
    {
        requires: [
            "ic-renderer-css"
        ]
    }
);
