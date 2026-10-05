var old = panels();
for (var i = 0; i < old.length; i++) {
    old[i].remove();
}

var acts = desktopsForActivity(currentActivity());
for (var j = 0; j < acts.length; j++) {
    var d = acts[j];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/Vendetta/");
    d.writeConfig("PreviewImage", "file:///usr/share/wallpapers/Vendetta/");
}

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
