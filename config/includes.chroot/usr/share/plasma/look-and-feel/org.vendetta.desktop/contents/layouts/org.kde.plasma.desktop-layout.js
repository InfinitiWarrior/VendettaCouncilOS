// Vendetta Council OS — panel & dock layout.
// Runs when the look-and-feel is applied (first login via vendetta-apply-theme).
// Brief metrics: 40px top panel, 64px left icon dock.

// wipe whatever panels a stock profile created
var old = panels();
for (var i = 0; i < old.length; i++) {
    old[i].remove();
}

// every desktop: Vendetta wallpaper via the image plugin.
// (the LnF `defaults` [Wallpaper] key is NOT auto-applied on a fresh profile —
//  plasmashell only reads the layout script, so the image must be set here.)
var acts = desktopsForActivity(currentActivity());
for (var j = 0; j < acts.length; j++) {
    var d = acts[j];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/Vendetta/");
    d.writeConfig("PreviewImage", "file:///usr/share/wallpapers/Vendetta/");
}

// --- top panel: 40px, launcher + spacer + tray + clock ---
var top = new Panel;
top.location = "top";
top.height = 40;
top.floating = false;
top.alignment = "left";

var kickoff = top.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "vendetta");

top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
top.addWidget("org.kde.plasma.digitalclock");

// --- left dock: 64px thick, icon-only tasks, shrinks to fit ---
var dock = new Panel;
dock.location = "left";
dock.height = 64;
dock.floating = true;
dock.hiding = "dodgewindows";
dock.alignment = "center";
dock.lengthMode = "fit";
dock.minimumLength = 0;

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:systemsettings.desktop",
    "applications:org.kde.dolphin.desktop",
    "preferred://browser",
    "applications:org.kde.konsole.desktop"
]);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("iconSpacing", 1);
