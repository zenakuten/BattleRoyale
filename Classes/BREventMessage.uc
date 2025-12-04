class BREventMessage extends LocalMessage;

var localized string Messages[10];

static function string GetString(
	optional int SwitchNum,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject 
	)
{
    SwitchNum = Clamp(SwitchNum, 0, 9);
    return Default.Messages[SwitchNum];
}



defaultproperties
{
    bIsUnique=True
    bFadeMessage=True
    DrawColor=(G=0,R=255)
    FontSize=1

    Messages(0)="You died"
    Messages(1)="You died"
    Messages(2)="You died"
    Messages(3)="You died"
    Messages(4)="You died"
    Messages(5)="You died"
    Messages(6)="You died"
    Messages(7)="You died"
    Messages(8)="You died"
    Messages(9)="You died"
}