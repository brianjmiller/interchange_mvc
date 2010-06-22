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
    "ic-manage-plugin-tabio",
    function(Y) {

        var ManageTabIO = function(config) {
            ManageTabIO.superclass.constructor.apply(this, arguments);
        };

        ManageTabIO.ATTRS = {
            content_node_template: {
                value: '<div class="yui3-tab-panel-content"></div>'
            },
            src_node_template: {
                value: '<div class="yui3-tab-panel-src"></div>'
            },
            related_node_template: {
                value: '<div class="yui3-tab-panel-related"></div>'
            },
            related: {
                value: null
            },
            content: {
                value: null
            },
            parent_node: {
                value: null
            }
        },

        Y.extend(ManageTabIO, Y.Plugin.WidgetIO, {

            initializer: function() {
                Y.log('tab_io::initializer');
                var tab = this.get('host');
                tab.on('selectedChange', this.afterSelectedChange);
            },
            
            afterSelectedChange: function(e) { // this === tab
                Y.log('tab_io::afterSelectedChange');
                this.get('panelNode').setContent(''); // clean slate
                if (e.newVal) { // tab has been selected
                    if (this.io.get('content')) {
                        Y.log('has content!');
                        this.io.addContent(
                            this.io.get('content'),
                            this.get('panelNode')
                        );
                    }
                    if (this.io.get('uri')) {
                        Y.log('has src!');
                        this.io.refresh();
                    }
                    if (this.io.get('related')) {
                        Y.log('has related! related: ' + this.io.get('related'));
                        this.io.addRelated(
                            this.io.get('related'),
                            this.get('panelNode')
                        );
                    }
                }
            },

            addContent: function (content, parent) {
                var content_node = this._buildEmptyContentNode();
                if (Y.Lang.isString(content)) {
                    content_node.setContent(content);
                }
                else if (Y.Lang.isObject(content)) {
                    content_node.setContent(
                        this._buildContentString(content)
                    );
                }
                parent.prepend(content_node);
            },

            addSrc: function(response, parent) {
                Y.log('tab_io::addSrc');
                var tab = this.get('host');
                Y.log(this.get('uri'));
                Y.log(response);
                if (response) {
                    var data = this._parseJSON(response);
                    var content_str = this._buildContentString(data);
                    var src_node = this._buildEmptySrcNode();
                    src_node.setContent(content_str);
                    if (Y.Lang.isValue(response.related)) {
                        this.addRelated(response.related, src_node);
                    }
                    parent.append(src_node);
                }
            },

            addRelated: function (related_ary, parent) {
                Y.log('tab_io::addRelated');
                Y.log(related_ary);
                var related_node = this._buildEmptyRelatedNode();
                Y.log('related node text: ' + related_node.get('text'));
                var tree = this._buildRelatedTreeview(related_ary);
                tree.plug(Y.IC.ManageTreeview);
                related_node.append(tree);
                parent.append(related_node);
            },

            _defStartHandler: function (id, o) {
                this._activeIO = o;
                // this.setContent('');
                // this._toggleLoadingClass(true);
            },

            _defSuccessHandler: function (id, o) {
                Y.log('tab_io::_defSuccessHandler');
                Y.log(this);
                parent = this.get('parent_node') || null;
                if (!parent) {
                    parent = this.get('host').get('panelNode');
                }
                this.addSrc(o.responseText, parent);
            },

            _parseJSON: function (json_str) {
                var json = {};
                try {
                    json = Y.JSON.parse(json_str);
                }
                catch (e) {
                    Y.log("Can't parse JSON: " + e, "error");
                    Y.log(json_str);
                }
                return json;
            },

            _buildContentString: function (data) {
                Y.log('tab_io::_buildContentString');
                var content = [];
                if (Y.Lang.isValue(data.object_name)) {
                    content.push('<h3>' + data.object_name + '</h3>');
                }
                if (Y.Lang.isValue(data.pk_settings)) {
                    content.push(
                        data.pk_settings[0].field + 
                            ": " + data.pk_settings[0].value)
                    ;
                }
                if (Y.Lang.isValue(data.other_settings)) {
                    content.push("<br /><br />");
                    for (i = 0; i < data.other_settings.length; i += 1) {
                        row = data.other_settings[i];
                        content.push(row.field + ": " + row.value + "<br />");
                    }
                }
                return content.join('');
            },

            _buildRelatedTreeview: function (related_ary) {
                Y.log('tab_io::_buildRelatedTreeview');
                if (related_ary.length) {
                    var ul = Y.Node.create('<ul></ul>');
                    var items = [];
                    Y.each(related_ary, function (v, i) {
                        items[v.order] = Y.Node.create('<li><span>' + v.label + '</span></li>');
                        // add content and/or src
                        if (Y.Lang.isValue(v.related)) {
                            items[v.order].append(this._buildRelatedTreeview(v.related));
                        }
                    }, this);
                    Y.each(items, function (v) {
                        ul.append(v);
                    });
                    return ul;
                }
                else {
                    return Y.Node.create(
                        "<div>There seem to be related nodes - but I can't find them...</div>"
                    );
                }
            },

            _buildEmptyContentNode: function () {
                return Y.Node.create(this.get('content_node_template'));
            },

            _buildEmptySrcNode: function () {
                return Y.Node.create(this.get('src_node_template'));
            },

            _buildEmptyRelatedNode: function (data) {
                return Y.Node.create(this.get('related_node_template'));
            },
            
            _toggleLoadingClass: function(add) {
                // noop
            }

        }, {
            NAME: 'ic_manage_tabio',
            NS: 'io'
        });

        Y.namespace("IC");
        Y.IC.ManageTabIO = ManageTabIO;

    },
    "@VERSION@",
    {
        requires: [
            "gallery-widget-io",
            "gallery-treeviewlite"
        ]
    }
);
