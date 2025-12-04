class BattleRoyaleLoginMenu extends UT2K4OnslaughtLoginMenu;

var() GUITabItem BattleRoyaleMapPanel;

function AddPanels()
{
	Panels.Insert(0,1);
	Panels[0] = BattleRoyaleMapPanel;
	Panels[1].ClassName = "BattleRoyale.UT2K4Tab_PlayerLoginControlsBattleRoyale";

	super(UT2K4PlayerLoginMenu).AddPanels();
}

defaultproperties
{
    BattleRoyaleMapPanel=(ClassName="BattleRoyale.UT2K4Tab_BattleRoyaleMap",Caption="Map",Hint="Map of the area")
}