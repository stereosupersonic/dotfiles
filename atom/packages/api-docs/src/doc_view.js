'use babel';

const $ = require('jquery');
const Disposable = require('atom').Disposable;
const Emitter = require('atom').Emitter;
const Highlight = require('./highlight');
const Resource = require('./resource');
const ScrollView = require('atom-space-pen-views').ScrollView;
const Url = require('url');

class DocView extends ScrollView {
  static DOC_STYLE_LIGHT_ = '';
  static DOC_STYLE_DARK_ = '';
  static DOC_STYLE_PROMISE_ = Resource.get('style-light.css').then(result => DocView.DOC_STYLE_LIGHT_ = result)
      .then(() => Resource.get('style-dark.css')).then(result => DocView.DOC_STYLE_DARK_ = result);

  static content() {
    // Magic required to enable scrolling and keyboard shortcuts for scrolling.
    return this.div({class: 'api-docs-doc', tabindex: -1});
  }

  constructor(library, url) {
    super();
    this.emitter_ = new Emitter();
    this.library_ = library;
    this.title_ = 'Loading...';
    this.url_ = url;
    this.pane_ = null;
  }

  setView(url) {
    // Set the view only after DOC_STYLE_{LIGHT|DARK}_ are set.
    DocView.DOC_STYLE_PROMISE_.then(() => {
      const parsedUrl = Url.parse(url, true);
      const path = parsedUrl.pathname.substr(1);
      const docset = this.library_.get(parsedUrl.hostname);

      let style = DocView.DOC_STYLE_LIGHT_;
      let styleClass = 'api-docs-theme-light';
      if (atom.config.get('api-docs._theme') == 'Dark') {
        style = DocView.DOC_STYLE_DARK_;
        styleClass = 'api-docs-theme-dark'
      }

      // We should call `createShadowRoot()` on `this.element` but Atom crashes
      // when a link is clicked inside a shadow root (atom/atom#5388).
      const root = this.element;
      root.innerHTML = `<style type="text/css">${style}</style>`;
      root.innerHTML += `<div class="${docset.classNames}" style="font-size: 10pt">${docset.getContent(path)}</div>`;
      root.classList.add(styleClass);

      // Set up click handlers for relative URLs so we can resolve internally.
      const elements = $(root).find('a');
      for (let i = 0; i < elements.length; ++i) {
        const href = elements[i].getAttribute('href');
        if (href && !href.startsWith('http')) {
          elements[i].onclick = event => this.setView(Url.resolve(url, href));
        }
      }

      Highlight(docset.type, root);

      this.title_ = docset.getTitle(path);
      this.emitter_.emit('did-change-title');
    });
  }

  destroy() {
    this.pane_.destroy();
  }

  attached() {
    this.pane_ = atom.workspace.paneForURI(this.getURI());
    this.pane_.activateItem(this);
  }

  onDidChangeTitle(callback) {
    return this.emitter_.on('did-change-title', callback);
  }

  onDidChangeModified(callback) {
    return new Disposable();
  }

  // Required to find the pane for this instance.
  getURI() {
    return this.url_;
  }

  getTitle() {
    return this.title_;
  }
}

module.exports = DocView;
