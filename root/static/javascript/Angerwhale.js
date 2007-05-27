Angerwhale = {
    TagEditor: function (options) {
        this.element = $(options.element);
        this.control = $(options.control);
        this.url = options.url;

        this.onUpdate = options.onUpdate;

        this.initialize();
    }
};

update(Angerwhale.TagEditor.prototype, {
        initialize: function () {
            this.editing = false;
            this.cancelText = 'cancel';
            this.form = null;
            this.input = null;
            this.state = 'initialized';

            connect(this.control, 'onclick', this, 'openEditor');
        },
        createForm: function () {
            this.input = INPUT();
            /* disable for now. enabling seems to be broken
            setNodeAttribute(this.input, 'disabled', true);
            */

            var form = FORM({}, this.input);
            var ok_button = A({style: "text-decoration: underline;"}, 'ok');
            connect(ok_button, 'onclick', this, 'submitForm');

            this.form = DIV();
            appendChildNodes(this.form, form, ok_button);
        },
        openEditor: function () {
            if (this.editing) {
                return;
            }

            this.editing = true;

            blindUp(this.element.parentNode, {
                                duration: 0.1,
                afterFinish: bind(function () {
                    hideElement(this.control);

                    this.createForm();
                    insertSiblingNodesBefore(this.element, this.form);

                    this.oldElement = this.element;
                    var new_element = A({style: "text-decoration: underline;"}, this.cancelText);
                    connect(new_element, 'onclick', this, 'cancelEdit');
                    swapDOM(this.element, new_element);
                    this.element = new_element;

                    /* FIXME: request current tags while blinding down? */
                    blindDown(this.form.parentNode, {
                                                duration: 0.1,
                        afterFinish: bind(function () {
                            this.doRequest();
                        }, this)
                    });
                }, this)
            });
        },
        closeEditor: function () {
            blindUp(this.form.parentNode, {
                                duration: 0.1,
                afterFinish: bind(function () {
                    removeElement(this.form);

                    swapDOM(this.element, this.oldElement);
                    this.element = this.oldElement;

                    setDisplayForElement('inline', this.control);

                    this.editing = false;

                    blindDown(this.element.parentNode, {duration: 0.1});
                }, this)
            });
        },
        cancelEdit: function () {
            this.closeEditor();
        },
        doRequest: function () {
            doXHR(this.url).addCallbacks(
                bind(function (response) {
                    /* doesn't work?
                    setNodeAttribute(this.input, 'disabled', false);
                    */

                    Highlight(this.input);
                    this.input.value = response.responseText;

                    this.state = 'loaded';
                }, this),
                bind(function (error) {
                    this.input.value = error.req.responseText; /* FIXME: empty with opera? */
                    setStyle(this.input, 
                                                 { 'background-color': '#ff3333', 'color': '#ffffff'});
                    shake(this.input);
                }, this)
            );
        },
        submitForm: function () {
            if (this.state != 'loaded') {
                return;
            }

            doXHR(this.url, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    sendContent: queryString({value: this.input.value})
            }).addCallbacks(
                bind(function (response) {
                    this.oldElement.innerHTML = response.responseText; /* TODO: use JSON! */
                    Highlight(this.input);

                    if (this.onUpdate) {
                        this.onUpdate();
                    }

                    this.closeEditor();
                }, this),
                bind(function (error) {
                    shake(this.input, {
                        afterFinish: bind(this.closeEditor, this)
                    });
                }, this)
            );
        }
});
