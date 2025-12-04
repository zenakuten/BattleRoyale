class StormPain extends DamageType;
static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictemHealth )
{
    HitEffects[0] = class'HitSmoke';
}
defaultproperties
{
    DeathString="%o fell victim to the storm"
    FemaleSuicide="%o fell victim to the storm"
    MaleSuicide="%o fell victim to the storm"
}