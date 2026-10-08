---
routeAlias: setup
---

## Install before the first practical

<div class="text-sm">

| Tool | What it is for | Get it |
| --- | --- | --- |
| **Visual Studio Code** | the editor every practical runs in | [code.visualstudio.com/download](https://code.visualstudio.com/download) |
| **Dyad Studio** extension | models and simulation; installs Julia with it | VS Code → Extensions → search `Dyad`, or the [Marketplace](https://marketplace.visualstudio.com/items?itemName=JuliaComputing.dyad-studio) |
| **JuliaHub** account | sign-in that unlocks Dyad's libraries | [juliahub.com](https://juliahub.com) |
| **Git** | version control for your work | [git-scm.com/downloads](https://git-scm.com/downloads) |
| **GitHub** account | hosts your repository; you hand in through it | [github.com/signup](https://github.com/signup) |

> **Do it at home** — After installing the extension, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>, run
> **Walkthrough → Installing Dyad** and sign in to JuliaHub. The first start
> downloads and compiles libraries and takes several minutes.

</div>

<!--
**Say:** five things, all free. Install them before the first practical,
not in it — the first Dyad start alone takes minutes, and thirty laptops downloading at
once on the room's Wi-Fi is slow.

**Alternative:** JuliaHub also ships Dyad Studio as a standalone app, with
VS Code built in (help.juliahub.com/dyad/dev/installation.html). Either works. ARM Windows,
ARM Linux and Intel Macs have no official build and need the manual Julia route on that
page.

**Requirements:** at least 4 CPU cores and 8 GB of RAM.
-->

---

## Create a GitHub account

<div class="grid grid-cols-2 gap-8">
<div class="text-sm">

1. Go to [github.com/signup](https://github.com/signup); enter an email,
   a password and a **username**. The username appears on all your
   work, so keep it professional.
2. Confirm the email GitHub sends you.
3. Turn on **two-factor authentication** when GitHub asks — an
   authenticator app on your phone is enough.
4. Optional: with your university email, apply for the free
   [Student Developer Pack](https://education.github.com/pack).

</div>
<div>

#### Then tell Git who you are

<p class="text-sm">Once, in a terminal, with the same email as on GitHub:</p>

```bash
git config --global user.name  "Jana Novakova"
git config --global user.email "jana@example.com"
```

<p class="text-sm">In VS Code, click the <strong>Accounts</strong> icon (bottom left) →
<strong>Sign in with GitHub</strong>, so it can push for you.</p>

</div>
</div>

<!--
**Say:** the email in `git config` is what links each commit to
your GitHub account. If it does not match, your commits show up without your name.
-->

---

## How Git works

<div class="grid grid-cols-[1fr_1.4fr] gap-8 items-start">
<div class="text-sm">

- **Repository** — a folder whose history Git keeps.
- **Commit** — a saved snapshot of the files, with a message saying
  what changed. You can always go back to one.
- **Branch** — a line of commits. `main` is the accepted
  version; you work on your own branch.
- **Remote** — the copy on GitHub. *Push* uploads your commits,
  *pull* downloads others'.

</div>
<svg viewBox="0 0 560 360" role="img" aria-label="Files in your folder are staged with git add, saved as a commit with git commit, uploaded to GitHub with git push, and downloaded back with git pull." style="width:100%;font-family:inherit">
  <defs>
    <marker id="git-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#1f5fa8"></path>
    </marker>
  </defs>
  <rect x="10" y="20" width="160" height="70" rx="8" fill="#f3f6fa" stroke="#9aa9bb"></rect>
  <text x="90" y="52" text-anchor="middle" fill="#1b2533" style="font-size:20px">Your folder</text>
  <text x="90" y="76" text-anchor="middle" fill="#4a5a6b" style="font-size:15px">files you edit</text>
  <rect x="10" y="150" width="160" height="70" rx="8" fill="#f3f6fa" stroke="#9aa9bb"></rect>
  <text x="90" y="182" text-anchor="middle" fill="#1b2533" style="font-size:20px">Staged</text>
  <text x="90" y="206" text-anchor="middle" fill="#4a5a6b" style="font-size:15px">ready to commit</text>
  <rect x="10" y="280" width="160" height="70" rx="8" fill="#f3f6fa" stroke="#9aa9bb"></rect>
  <text x="90" y="312" text-anchor="middle" fill="#1b2533" style="font-size:20px">Local history</text>
  <text x="90" y="336" text-anchor="middle" fill="#4a5a6b" style="font-size:15px">your commits</text>
  <rect x="380" y="150" width="170" height="70" rx="8" fill="#e8f0fa" stroke="#1f5fa8"></rect>
  <text x="465" y="182" text-anchor="middle" fill="#1b2533" style="font-size:20px">GitHub</text>
  <text x="465" y="206" text-anchor="middle" fill="#4a5a6b" style="font-size:15px">the remote</text>
  <line x1="90" y1="92" x2="90" y2="146" stroke="#1f5fa8" stroke-width="2.5" marker-end="url(#git-arrow)"></line>
  <text x="102" y="125" fill="#1f5fa8" style="font-size:16px;font-family:monospace">git add</text>
  <line x1="90" y1="222" x2="90" y2="276" stroke="#1f5fa8" stroke-width="2.5" marker-end="url(#git-arrow)"></line>
  <text x="102" y="255" fill="#1f5fa8" style="font-size:16px;font-family:monospace">git commit</text>
  <path d="M172,315 C300,315 380,290 440,224" fill="none" stroke="#1f5fa8" stroke-width="2.5" marker-end="url(#git-arrow)"></path>
  <text x="290" y="348" fill="#1f5fa8" style="font-size:16px;font-family:monospace">git push</text>
  <path d="M465,148 C430,60 300,55 174,55" fill="none" stroke="#1f5fa8" stroke-width="2.5" marker-end="url(#git-arrow)"></path>
  <text x="300" y="50" fill="#1f5fa8" style="font-size:16px;font-family:monospace">git pull</text>
</svg>
</div>

<!--
**Say:** Git is a save system with memory. Every commit is a snapshot you
can return to, so you can try something risky in a model and undo it.

**Walk the picture:** you edit files; `git add` picks which
changes go into the next snapshot; `git commit` saves it on your machine;
`git push` sends it to GitHub. `git pull` brings changes from GitHub
back — anything changed there since your last pull.

**Say:** nothing reaches GitHub until you push. A commit on your laptop
only is not handed in.
-->

---

## Handing in a task

<div class="text-sm">

<table>
  <thead>
    <tr><th>Step</th><th>Command</th><th>In VS Code</th></tr>
  </thead>
  <tbody>
    <tr><td>Get your repository (once)</td><td><code>git clone &lt;url&gt;</code></td>
      <td><kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> → <strong>Git: Clone</strong></td></tr>
    <tr><td>Start a task on its own branch</td><td><code>git switch -c task-1</code></td>
      <td>branch name in the status bar → <strong>Create new branch</strong></td></tr>
    <tr><td>Save progress, often</td><td><code>git add dyad/Car.dyad</code><br>
      <code>git commit -m "Add the car body"</code></td>
      <td><strong>Source Control</strong> panel: <strong>+</strong> to stage, message,
      <strong>Commit</strong></td></tr>
    <tr><td>Upload</td><td><code>git push</code></td>
      <td><strong>Publish Branch</strong> / <strong>Sync Changes</strong></td></tr>
    <tr><td>Hand in</td><td colspan="2">on GitHub: <strong>Compare &amp; pull request</strong>
      → describe what you did → <strong>Create pull request</strong></td></tr>
  </tbody>
</table>

A **pull request** asks for your branch to be merged into
`main`. It is where your work is reviewed and commented on.

</div>

<!--
**Say:** one branch per task, one pull request per task. Commit in small
steps with a message that says what you did — "Add the car body", not "update".

**Say:** you can push more commits to the same branch after opening the
pull request; they appear in it. That is how you answer review comments.

**Practical:** the first practical goes through this once, end to end.
-->
