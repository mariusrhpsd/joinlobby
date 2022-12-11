## set your steamapi key and your own profile ID
$steamkey = ""
$profileid = ""

## Starts Timer

$StartTime = $(get-date)

## Defines Divide-Array to circunvent steamapi query limit of 100
function Divide-Array{
    param(
	[Parameter(Mandatory)]
        $array,
        [Parameter(Mandatory)]
        $arraysize
    )
    $arraysets = [math]::Truncate(($array.Count-1)/$arraysize)
    $count = 0
    $blocks = @()
    while ($count -le $arraysets){
        $n = $arraysize*$count
        $start = 0+$n
        $finish = $arraysize+$n-1
        $block = [pscustomobject]@{block = $array[$start..$finish]}
        $blocks+=$block
        $count+=1
    }
    return $blocks
}

## Defines function to join lobbies
function Join-Lobby{
    param(
		[Parameter(Mandatory)]
		$object
    )
    $lobbylink = $object.join
    $nombre = $object.player
    Read-Host "Entrando al lobby de $nombre, presione enter para finalizar"
    cd "C:\Program Files (x86)\Steam\" 
    .\steam.exe $lobbylink
}
## define variables
$friendlist =
$friends =
$puesto = 1
$container = [System.Collections.Generic.List[System.Object]]@()

## set your steamapi key and your own profile ID
$steamkey = ""
$profileid = ""

## steam gameids to look for, set for Rev2 and GGXXAC+R
$gameids = @("520440","348550")


## Get friendlist and friend IDs
$friendlist = Invoke-RestMethod "http://api.steampowered.com/ISteamUser/GetFriendList/v0001/?key=$steamkey&steamid=$profileid"
$friendids = $friendlist.friendslist.friends.steamid

## Divide in sets of 100 to comply query limit
$idsets = Divide-Array -array $friendids -arraysize 100

## Validate in sets of 100 if friend is playing Rev2 or AC+r and adds custom objet to container
foreach($idset in $idsets){
    $steamids = ""
    foreach ($id in $idset.block){
    $id = "$id"
    $steamids = -join("$steamids",",","$id")
    }
    $friends = Invoke-RestMethod "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$steamkey&steamids=$steamids"
    foreach ($friend in $friends.response.players){
        if ($gameids -contains $friend.gameid -and !$friend.lobbysteamid -eq $False){
            $steamid = $friend.steamid
            $personaname = $friend.personaname
            $gameid = $friend.gameid
            $lobbysteamid = $friend.lobbysteamid
            $gameextrainfo = $friend.gameextrainfo
            $joinurl = -Join ("steam://joinlobby/","$gameid","/","$lobbysteamid","/","$steamid")
            $myObject = [PSCustomObject]@{
                Puesto=$puesto
                Player=$personaname
                Game=$gameextrainfo
                Join=$joinurl
            }
            $puesto+=1
            $container+=$myObject
        }
    }
}

## Shows the lobbies found as a table and asks for entry
$elapsedTime = $(get-date) - $StartTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
$totalTime
Write-Output $container  | Format-Table
[int]$picklobby = Read-Host "Que lobby queres entrar?"
$picklobby-=1

## Joins picked lobby
Join-Lobby -object $container[$picklobby]
