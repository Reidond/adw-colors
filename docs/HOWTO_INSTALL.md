<p align="center">
  <a href="#-how-to-download-and-install-a-theme">📥 How to Download and Install a Theme</a> •
  <a href="#-manual-installation">🛠 Manual Installation</a> •
  <a href="#-updates">🔄 Updates</a> •
  <a href="#-uninstall-a-theme">❌ Uninstall a Theme</a>
</p>

<h3>📥 How to Download and Install a Theme</h3>

<p>The install script requires <a href="https://github.com/lassekongo83/adw-gtk3">adw-gtk3</a> and a GNOME environment.</p>

<ol>
  <li>Clone this repository using <code>git</code>
    <pre><code class="language-bash">git clone https://github.com/lassekongo83/adw-colors.git</code></pre>
  </li>
  <li>Navigate to the cloned repository and run the install script:
    <pre><code class="language-bash">cd adw-colors
sh scripts/install.sh</code></pre>
    <p>Select the theme you want to install from the list.</p>
  </li>
  <li>If you use flatpak apps, run:
    <pre><code class="language-bash">sudo flatpak override --filesystem=xdg-config/gtk-3.0 && sudo flatpak override --filesystem=xdg-config/gtk-4.0</code></pre>
  </li>
  <li>Restart any open applications or log out and in again.</li>
</ol>

<b>Important note to Firefox users:</b> For Firefox to be able to use these themes you'll need to open `about:config` and set `widget.gtk.libadwaita-colors.enabled` to `false`.

<details>
  <summary><h3>🛠 Manual Installation</h3></summary>

  <ol>
    <li>Clone this repository using <code>git</code>
      <pre><code class="language-bash">git clone https://github.com/lassekongo83/adw-colors.git</code></pre>
    </li>
    <li>Navigate to the cloned repository:
      <pre><code class="language-bash">cd adw-colors</code></pre>
    </li>
    <li>Create a symbolic link from the theme you want to use to your GTK config directories. For example installing Plano2:
      <pre><code class="language-bash">mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
ln -s "themes/Plano2/gtk3-dark.css" "~/.config/gtk-3.0/gtk.css"
ln -s "themes/Plano2/gtk4-dark.css" "~/.config/gtk-4.0/gtk.css"
# And the assets directory as well if it exists
ln -s "themes/Plano2/assets" "~/.config/gtk-3.0/assets"
ln -s "themes/Plano2/assets" "~/.config/gtk-4.0/assets"</code></pre>
      <p>You may also need to change the theme to adw-gtk3 and color-scheme to <code>prefer-dark</code> if you haven't already:</p>
      <pre><code class="language-bash">gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"</code></pre>
      <p>Or if you're installing a light theme set it to:</p>
      <pre><code class="language-bash">gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"
gsettings set org.gnome.desktop.interface color-scheme "default"</code></pre>
    </li>
    <li>Restart any open applications or log out and in again.</li>
  </ol>
</details>

<h3>🔄 Updates</h3>

<p>Whenever you want to get the latest updates for a theme, navigate to the <code>adw-colors</code> directory and run:</p>
<pre><code class="language-bash">git pull</code></pre>

<h3>❌ Uninstall a Theme</h3>

<p>If you want to uninstall a theme, run:</p>
<pre><code class="language-bash">sh scripts/uninstall.sh</code></pre>
