import{b as c,c as k,d as h,e as r,f as p,g as y,h as f,k as $,l as R,n as g,o as b,q as C,r as x,t as z,w as F,x as T}from"./chunk-5VFYIKDE.js";var v="Speaker cues",n,l,s,E,w,o=class extends ${constructor(){super(...arguments);h(this,s);this.deck=null;h(this,n,null);this.report={status:"waiting",index:null,decks:0};h(this,l,null)}connectedCallback(){super.connectedCallback(),p(this,s,E).call(this)}disconnectedCallback(){super.disconnectedCallback(),k(this,n)?.stop(),r(this,n,null)}willUpdate(){this.dataset.deck=this.report.status,document.body.dataset.deck=this.report.status}render(){let{status:e,index:t,decks:d}=this.report,i=this.deck,a=i!==null&&t!==null?i.slides[t]:void 0;if(i!==null&&t!==null&&a===void 0)return f`
        <header>
          <h1>${v}</h1>
          <p><span class="position">—</span> · <span>${p(this,s,w).call(this)}</span></p>
          <p class="state" aria-live="polite">
            The deck is on slide ${t+1} of a deck this page has not loaded. Refresh it.
          </p>
        </header>
        <div class="cue-body"></div>
      `;let N=a===void 0?v:a.title??`Slide ${(t??0)+1}`,D=a===void 0||i===null?"\u2014":`${(t??0)+1} / ${i.slides.length}`;return f`
      <header>
        <h1>${N}</h1>
        <p><span class="position">${D}</span> · <span>${p(this,s,w).call(this)}</span></p>
        <p class="state" aria-live="polite">${G(e,d)}</p>
      </header>
      <div class="cue-body"></div>
    `}updated(){let{index:e}=this.report,t=this.deck,d=t!==null&&e!==null?t.slides[e]:void 0,i=this.renderRoot.querySelector(".cue-body");if(i!==null){if(e===null||d===void 0){i.replaceChildren(),r(this,l,null);return}e!==k(this,l)&&(T(i,d.notes),document.scrollingElement?.scrollTo({top:0}),r(this,l,e))}}};n=new WeakMap,l=new WeakMap,s=new WeakSet,E=async function(){let e=await x("/api/deck",C);this.deck=e,document.title=`${v} \xB7 ${b(e.path)}`,r(this,n,new z(e.path,t=>{this.report=t}))},w=function(){return this.deck===null?"":b(this.deck.path)},o.styles=[F,y`
      :host {
        display: block;
      }

      /* Sticky, because a cue long enough to scroll would otherwise take which slide it belongs
         to and whether anything is still confirming it off the top of the page. */
      header {
        position: sticky;
        inset-block-start: 0;
        padding-block-end: 0.75rem;
        margin-block-end: 1rem;
        background: var(--bg);
        border-block-end: 1px solid var(--edge);
      }

      h1 {
        margin: 0;
        font-size: 1.4rem;
      }

      p {
        margin-block: 0.25rem;
        color: var(--muted);
        font-size: 0.9rem;
      }

      .state {
        color: var(--warn);

        &::before {
          content: "";
          display: inline-block;
          inline-size: 0.5rem;
          block-size: 0.5rem;
          margin-inline-end: 0.35rem;
          border-radius: 50%;
          background: currentColor;
        }
      }

      :host([data-deck="live"]) .state {
        color: var(--ok);
      }

      /* Read across a lecture hall's worth of peripheral vision: a lecturer looking at the cues
         has to see that nothing is confirming them without reading the line. */
      :host([data-deck="lost"]) .state {
        color: var(--bad);
        font-weight: 600;
      }

      /* The cues are the page here rather than a panel over a slide, so they carry a reading
         size. */
      .cue-body {
        font-size: 1.05rem;
        line-height: 1.6;
      }
    `],c([g()],o.prototype,"deck",2),c([g()],o.prototype,"report",2),o=c([R("speaker-page")],o);function G(u,m){return u==="waiting"?"No deck window is driving this page; it follows one as soon as the deck is open.":u==="lost"?"The deck window is gone \u2014 these are the last cues it sent, not the live slide.":m>1?`${m} deck windows are driving this page \u2014 close all but one.`:"Following the deck."}
