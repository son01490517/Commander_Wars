// Automation script for tools/handheld/measure-ram.sh.
// Starts a 2-player AI-vs-AI match (stand-in for "1 human vs 1 AI") and prints
// RAMTEST markers that the measurement script parses.
var Init =
{
    started = false,
    main = function(menu)
    {
        if (!Init.started)
        {
            Init.started = true;
            settings.setBattleAnimationMode(GameEnums.BattleAnimationMode_None);
            settings.setCaptureAnimation(false);
            settings.setDay2dayScreen(false);
            GameConsole.print("RAMTEST: main menu", 2);
            menu.enterSingleplayer([".map"]);
        }
    },
    mapsSelection = function(menu)
    {
        menu.selectMap("RAMTEST_MAP_FOLDER", "RAMTEST_MAP_FILE");
        menu.buttonNext();
        menu.buttonNext();
        var selection = menu.getPlayerSelection();
        var map = selection.getMap();
        GameConsole.print("RAMTEST: map size " + map.getMapWidth() + "x" + map.getMapHeight() +
                          " players " + map.getPlayerCount(), 2);
        selection.selectPlayerAi(0, 2);
        selection.selectPlayerAi(1, 2);
        menu.startGame();
    },
    gameMenu = function(menu)
    {
        GameConsole.print("RAMTEST: in game", 2);
    },
    onVictory = function(menu)
    {
        GameConsole.print("RAMTEST: victory", 2);
    },
}
