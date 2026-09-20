/* Deck behavior: copy buttons, figure drop-in placeholders, and an on-slide cue panel.
   Everything here must work from file:// with no network — the deck is presented in a
   lecture hall and a failed fetch has no recovery. */

(function () {
  'use strict';

  // --- copy-to-clipboard ----------------------------------------------------------
  // navigator.clipboard is unavailable on a file:// origin in several browsers, so the
  // execCommand path is the one that actually runs during a lecture, not a legacy branch.

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }
    return new Promise(function (resolve, reject) {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      try {
        document.execCommand('copy') ? resolve() : reject();
      } catch (e) {
        reject(e);
      } finally {
        document.body.removeChild(ta);
      }
    });
  }

  function wireCopyButtons() {
    document.querySelectorAll('.demo').forEach(function (demo) {
      var code = demo.querySelector('pre code');
      var btn = demo.querySelector('button.copy');
      if (!code || !btn) return;
      btn.addEventListener('click', function () {
        copyText(code.textContent.replace(/\s+$/, '')).then(function () {
          btn.textContent = 'copied';
          btn.classList.add('done');
          setTimeout(function () {
            btn.textContent = 'copy';
            btn.classList.remove('done');
          }, 1600);
        }, function () {
          btn.textContent = 'select manually';
          setTimeout(function () { btn.textContent = 'copy'; }, 2400);
        });
      });
    });
  }

  // --- figure placeholders --------------------------------------------------------
  // A figure that has not been generated yet renders as a labelled placeholder rather
  // than a broken image. Dropping the file into assets/figures/ with the name the <img>
  // already points at is the whole of the hand-off: no markup changes.

  function placeholderFor(img) {
    var box = document.createElement('div');
    box.className = 'fig-missing';
    var src = img.dataset.intended || img.getAttribute('src');
    box.innerHTML =
      '<span class="tag">FIGURE NOT YET GENERATED</span>' +
      '<div class="what">' + (img.getAttribute('alt') || '') + '</div>' +
      '<div class="src">drop in: ' + src + '</div>';
    return box;
  }

  function wireFigures() {
    document.querySelectorAll('.fig img').forEach(function (img) {
      img.addEventListener('error', function () {
        if (img.dataset.replaced) return;
        // A plot saved as PNG is served under the same base name, so a notebook that
        // emits raster output drops in without touching the markup either.
        var src = img.getAttribute('src');
        if (/\.svg$/.test(src) && !img.dataset.triedPng) {
          img.dataset.triedPng = '1';
          img.dataset.intended = src;
          img.setAttribute('src', src.replace(/\.svg$/, '.png'));
          return;
        }
        img.dataset.replaced = '1';
        img.replaceWith(placeholderFor(img));
      });
      if (img.complete && img.naturalWidth === 0) {
        img.dispatchEvent(new Event('error'));
      }
    });
  }

  // --- on-slide cue panel ---------------------------------------------------------
  // The speaker view (S) is the intended way to read the notes. It opens a second window
  // and talks to it over postMessage, which a locked-down browser or a blocked popup can
  // deny; this panel reads the same <aside class="notes"> in the presentation window, so
  // the guidance is never stranded.

  function wireNotesPanel(deck) {
    var panel = document.createElement('div');
    panel.id = 'notes-panel';
    panel.innerHTML = '<h5>Speaker cues — press C to hide</h5><div class="body"></div>';
    document.body.appendChild(panel);
    var body = panel.querySelector('.body');

    function render() {
      var slide = deck.getCurrentSlide();
      var notes = slide ? slide.querySelector('aside.notes') : null;
      body.innerHTML = notes ? notes.innerHTML : '<p class="muted">No notes on this slide.</p>';
    }

    function toggle() {
      panel.classList.toggle('on');
      if (panel.classList.contains('on')) render();
    }

    deck.addKeyBinding(
      { keyCode: 67, key: 'C', description: 'Toggle on-slide speaker cues' },
      toggle
    );
    deck.on('slidechanged', function () {
      if (panel.classList.contains('on')) render();
    });
  }

  // --- footer ---------------------------------------------------------------------

  function wireFooter(deck) {
    var footer = document.createElement('div');
    footer.className = 'deck-footer';
    footer.innerHTML = '<span class="where"></span>';
    deck.getRevealElement().appendChild(footer);
    var where = footer.querySelector('.where');

    deck.on('slidechanged', function (event) {
      var horizontal = event.indexh;
      var section = document.querySelectorAll('.reveal .slides > section')[horizontal];
      var title = section ? (section.dataset.sectionTitle || '') : '';
      where.textContent = title;
      footer.style.visibility = event.indexh === 0 && event.indexv === 0 ? 'hidden' : 'visible';
    });
  }

  window.initDeck = function (deck) {
    wireCopyButtons();
    wireFigures();
    wireNotesPanel(deck);
    wireFooter(deck);
  };
})();
