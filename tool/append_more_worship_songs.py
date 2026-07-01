"""Append worship songs 401+ to samples/songs_library_template.json."""
import json
import os

SONGS_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "samples", "songs_library_template.json")


def song(number: str, key: str, title: str, lyrics: str) -> dict:
    return {
        "number": number,
        "key": key,
        "title": title,
        "lyrics": lyrics.strip(),
    }


NEW_SONGS = [
    song("401", "F", "What a Friend We Have in Jesus", """
What a friend we have in Jesus
All our sins and griefs to bear
What a privilege to carry
Everything to God in prayer
O what peace we often forfeit
O what needless pain we bear
All because we do not carry
Everything to God in prayer
Have we trials and temptations?
Is there trouble anywhere?
We should never be discouraged
Take it to the Lord in prayer
Can we find a friend so faithful
Who will all our sorrows share?
Jesus knows our every weakness
Take it to the Lord in prayer"""),
    song("402", "G", "When I Survey the Wondrous Cross", """
When I survey the wondrous cross
On which the Prince of glory died
My richest gain I count but loss
And pour contempt on all my pride
Forbid it, Lord, that I should boast
Save in the death of Christ my God
All the vain things that charm me most
I sacrifice them to His blood
See from His head, His hands, His feet
Sorrow and love flow mingled down
Did e'er such love and sorrow meet
Or thorns compose so rich a crown?"""),
    song("403", "G", "Leaning on the Everlasting Arms", """
What a fellowship, what a joy divine
Leaning on the everlasting arms
What a blessedness, what a peace is mine
Leaning on the everlasting arms
Chorus:
Leaning, leaning
Safe and secure from all alarms
Leaning, leaning
Leaning on the everlasting arms
Oh, how sweet to walk in this pilgrim way
Leaning on the everlasting arms
Oh, how bright the path grows from day to day
Leaning on the everlasting arms"""),
    song("404", "F", "Fairest Lord Jesus", """
Fairest Lord Jesus
Ruler of all nature
O Thou of God and man the Son
Thee will I cherish, Thee will I honor
Thou my soul's glory, joy and crown
Fair are the meadows, fairer still the woodlands
Robed in the blooming garb of spring
Jesus is fairer, Jesus is purer
Who makes the woeful heart to sing
Fair is the sunshine, fairer still the moonlight
And all the twinkling starry host
Jesus shines brighter, Jesus shines purer
Than all the angels heaven can boast"""),
    song("405", "G", "Crown Him with Many Crowns", """
Crown Him with many crowns
The Lamb upon His throne
Hark! How the heavenly anthem drowns
All music but its own
Awake, my soul, and sing
Of Him who died for thee
And hail Him as thy matchless King
Through all eternity
Crown Him the Lord of life
Who triumphed o'er the grave
And rose victorious in the strife
For those He came to save
His glories now we sing
Who died and rose on high
Who died eternal life to bring
And lives that death may die"""),
    song("406", "C", "A Mighty Fortress Is Our God", """
A mighty fortress is our God
A bulwark never failing
Our helper He amid the flood
Of mortal ills prevailing
For still our ancient foe
Doth seek to work us woe
His craft and power are great
And armed with cruel hate
On earth is not his equal
Did we in our own strength confide
Our striving would be losing
Were not the right Man on our side
The Man of God's own choosing
Dost ask who that may be?
Christ Jesus, it is He
Lord Sabaoth His name
From age to age the same
And He must win the battle"""),
    song("407", "G", "Abide with Me", """
Abide with me, fast falls the eventide
The darkness deepens, Lord with me abide
When other helpers fail and comforts flee
Help of the helpless, oh abide with me
Swift to its close ebbs out life's little day
Earth's joys grow dim, its glories pass away
Change and decay in all around I see
O Thou who changest not, abide with me
I need Thy presence every passing hour
What but Thy grace can foil the tempter's power?
Who like Thyself my guide and stay can be?
Through cloud and sunshine, Lord abide with me"""),
    song("408", "G", "And Can It Be", """
And can it be that I should gain
An interest in the Saviour's blood?
Died He for me, who caused His pain?
For me, who Him to death pursued?
Amazing love! How can it be
That Thou, my God, shouldst die for me?
He left His Father's throne above
So free, so infinite His grace
Emptied Himself of all but love
And bled for Adam's helpless race
'Tis mystery all! The Immortal dies
Who can explore His strange design?
In vain the firstborn seraph tries
To sound the depths of love divine"""),
    song("409", "G", "His Eye Is on the Sparrow", """
Why should I feel discouraged
Why should the shadows come
Why should my heart be lonely
And long for heaven and home
When Jesus is my portion
My constant friend is He
His eye is on the sparrow
And I know He watches me
Chorus:
I sing because I'm happy
I sing because I'm free
His eye is on the sparrow
And I know He watches me
Let not your heart be troubled
His tender word I hear
And resting on His goodness
I lose my doubts and fears"""),
    song("410", "G", "I Surrender All", """
All to Jesus I surrender
All to Him I freely give
I will ever love and trust Him
In His presence daily live
Chorus:
I surrender all
I surrender all
All to Thee my blessed Saviour
I surrender all
All to Jesus I surrender
Humbly at His feet I bow
Worldly pleasures all forsaken
Take me, Jesus, take me now
All to Jesus I surrender
Make me, Saviour, wholly Thine
Let me feel the Holy Spirit
Truly know that Thou art mine"""),
    song("411", "G", "Jesus Paid It All", """
I hear the Saviour say
Thy strength indeed is small
Child of weakness watch and pray
Find in Me thine all in all
Chorus:
Jesus paid it all
All to Him I owe
Sin had left a crimson stain
He washed it white as snow
Lord, now indeed I find
Thy power and Thine alone
Can change the leper's spots
And melt the heart of stone
For nothing good have I
Whereby Thy grace to claim
I'll wash my garments white
In the blood of Calvary's Lamb"""),
    song("412", "G", "Joyful, Joyful, We Adore Thee", """
Joyful, joyful, we adore Thee
God of glory, Lord of love
Hearts unfold like flowers before Thee
Opening to the sun above
Melt the clouds of sin and sadness
Drive the dark of doubt away
Giver of immortal gladness
Fill us with the light of day
All Thy works with joy surround Thee
Earth and heaven reflect Thy rays
Stars and angels sing around Thee
Center of unbroken praise
Field and forest, vale and mountain
Flowery meadow, flashing sea
Chanting bird and flowing fountain
Praising Thee eternally"""),
    song("413", "G", "Praise to the Lord, the Almighty", """
Praise to the Lord, the Almighty, the King of creation
O my soul, praise Him, for He is thy health and salvation
All ye who hear, now to His temple draw near
Praise Him in glad adoration
Praise to the Lord, who o'er all things so wondrously reigneth
Shelters thee under His wings, yea, so gently sustaineth
Hast thou not seen how thy desires e'er have been
Granted in what He ordaineth
Praise to the Lord, who doth prosper thy work and defend thee
Surely His goodness and mercy here daily attend thee
Ponder anew what the Almighty can do
If with His love He befriend thee"""),
    song("414", "G", "Trust and Obey", """
When we walk with the Lord
In the light of His Word
What a glory He sheds on our way
While we do His good will
He abides with us still
And with all who will trust and obey
Chorus:
Trust and obey
For there's no other way
To be happy in Jesus
But to trust and obey
Not a shadow can rise
Not a cloud in the skies
But His smile quickly drives it away
Not a doubt or a fear
Not a sigh or a tear
Can abide while we trust and obey"""),
    song("415", "G", "Take My Life and Let It Be", """
Take my life and let it be
Consecrated, Lord, to Thee
Take my moments and my days
Let them flow in ceaseless praise
Take my hands and let them move
At the impulse of Thy love
Take my feet and let them be
Swift and beautiful for Thee
Take my voice and let me sing
Always, only, for my King
Take my lips and let them be
Filled with messages from Thee
Take my silver and my gold
Not a mite would I withhold
Take my intellect and use
Every power as Thou shalt choose"""),
    song("416", "G", "In the Garden", """
I come to the garden alone
While the dew is still on the roses
And the voice I hear falling on my ear
The Son of God discloses
Chorus:
And He walks with me, and He talks with me
And He tells me I am His own
And the joy we share as we tarry there
None other has ever known
He speaks, and the sound of His voice
Is so sweet the birds hush their singing
And the melody that He gave to me
Within my heart is ringing"""),
    song("417", "G", "All Hail the Power of Jesus' Name", """
All hail the power of Jesus' name
Let angels prostrate fall
Bring forth the royal diadem
And crown Him Lord of all
Bring forth the royal diadem
And crown Him Lord of all
O seed of Israel's chosen race
Ye ransomed from the fall
Hail Him who saves you by His grace
And crown Him Lord of all
Hail Him who saves you by His grace
And crown Him Lord of all
Let every kindred, every tribe
On this terrestrial ball
To Him all majesty ascribe
And crown Him Lord of all
To Him all majesty ascribe
And crown Him Lord of all"""),
    song("418", "Ab", "Battle Hymn of the Republic", """
Mine eyes have seen the glory of the coming of the Lord
He is trampling out the vintage where the grapes of wrath are stored
He hath loosed the fateful lightning of His terrible swift sword
His truth is marching on
Chorus:
Glory, glory, hallelujah
Glory, glory, hallelujah
Glory, glory, hallelujah
His truth is marching on
He has sounded forth the trumpet that shall never call retreat
He is sifting out the hearts of men before His judgment seat
Oh, be swift, my soul, to answer Him! Be jubilant, my feet!
Our God is marching on"""),
    song("419", "G", "Christ the Lord Is Risen Today", """
Christ the Lord is risen today, Alleluia!
Earth and heaven in chorus say, Alleluia!
Raise your joys and triumphs high, Alleluia!
Sing, ye heavens, and earth reply, Alleluia!
Love's redeeming work is done, Alleluia!
Fought the fight, the battle won, Alleluia!
Death in vain forbids Him rise, Alleluia!
Christ has opened paradise, Alleluia!
Lives again our glorious King, Alleluia!
Where, O death, is now thy sting? Alleluia!
Once He died our souls to save, Alleluia!
Where thy victory, O grave? Alleluia!"""),
    song("420", "G", "Jesus, Lover of My Soul", """
Jesus, lover of my soul
Let me to Thy bosom fly
While the nearer waters roll
While the tempest still is high
Hide me, O my Saviour, hide
Till the storm of life is past
Safe into the haven guide
O receive my soul at last
Other refuge have I none
Hangs my helpless soul on Thee
Leave, ah! leave me not alone
Still support and comfort me
All my trust on Thee is stayed
All my help from Thee I bring
Cover my defenseless head
With the shadow of Thy wing"""),
    song("421", "G", "At the Cross (Love Ran Red)", """
At the cross, at the cross
Where I first saw the light
And the burden of my heart rolled away
It was there by faith I received my sight
And now I am happy all the day
At the cross, at the cross
Where I first saw the light
And the burden of my heart rolled away
It was there by faith I received my sight
And now I am happy all the day"""),
    song("422", "G", "My Hope Is Built on Nothing Less", """
My hope is built on nothing less
Than Jesus' blood and righteousness
I dare not trust the sweetest frame
But wholly lean on Jesus' name
Chorus:
On Christ the solid rock I stand
All other ground is sinking sand
All other ground is sinking sand
When darkness veils His lovely face
I rest on His unchanging grace
In every high and stormy gale
My anchor holds within the veil
His oath, His covenant, His blood
Support me in the whelming flood
When all around my soul gives way
He then is all my hope and stay"""),
    song("423", "G", "O for a Thousand Tongues to Sing", """
O for a thousand tongues to sing
My great Redeemer's praise
The glories of my God and King
The triumphs of His grace
My gracious Master and my God
Assist me to proclaim
To spread through all the earth abroad
The honors of Thy name
Jesus! the name that charms our fears
That bids our sorrows cease
'Tis music in the sinner's ears
'Tis life and health and peace
He breaks the power of canceled sin
He sets the prisoner free
His blood can make the foulest clean
His blood availed for me"""),
    song("424", "G", "There Is a Redeemer", """
There is a Redeemer
Jesus, God's own Son
Precious Lamb of God, Messiah
Holy One
Chorus:
Thank You, O my Father
For giving us Your Son
And leaving Your Spirit till
The work on earth is done
Jesus, my Redeemer
Name above all names
Precious Lamb of God, Messiah
Oh, for sinners slain
When I stand in glory
I will see His face
There I'll serve my King forever
In that holy place"""),
    song("425", "G", "To God Be the Glory", """
To God be the glory, great things He hath done
So loved He the world that He gave us His Son
Who yielded His life an atonement for sin
And opened the life gate that all may go in
Chorus:
Praise the Lord, praise the Lord
Let the earth hear His voice
Praise the Lord, praise the Lord
Let the people rejoice
O come to the Father through Jesus the Son
And give Him the glory, great things He hath done
O perfect redemption, the purchase of blood
To every believer the promise of God
The vilest offender who truly believes
That moment from Jesus a pardon receives"""),
    song("426", "G", "Sweet Beulah Land", """
I'm kind of homesick for a country
To which I've never been before
No sad goodbyes will there be spoken
For time won't matter anymore
Chorus:
Beulah Land, I'm longing for you
And some day on thee I'll stand
There my home shall be eternal
Beulah Land, sweet Beulah Land
I'm looking now across the river
Where my faith will end in sight
There's just a few more days to labor
Then I will take my heavenly flight"""),
    song("427", "G", "Pass Me Not, O Gentle Saviour", """
Pass me not, O gentle Saviour
Hear my humble cry
While on others Thou art calling
Do not pass me by
Chorus:
Saviour, Saviour, hear my humble cry
While on others Thou art calling
Do not pass me by
Let me at Thy throne of mercy
Find a sweet relief
Kneeling there in deep contrition
Help my unbelief
Trusting only in Thy merit
Would I seek Thy face
Heal my wounded, broken spirit
Save me by Thy grace"""),
    song("428", "G", "It Is Well With My Soul", """
When peace like a river attendeth my way
When sorrows like sea billows roll
Whatever my lot, Thou hast taught me to say
It is well, it is well with my soul
Chorus:
It is well with my soul
It is well, it is well with my soul
Though Satan should buffet, though trials should come
Let this blest assurance control
That Christ hath regarded my helpless estate
And hath shed His own blood for my soul
My sin, oh the bliss of this glorious thought
My sin, not in part, but the whole
Is nailed to His cross, and I bear it no more
Praise the Lord, praise the Lord, O my soul"""),
    song("429", "F", "Savior, Like a Shepherd Lead Us", """
Savior, like a shepherd lead us
Much we need Thy tender care
In Thy pleasant pastures feed us
For our use Thy folds prepare
Blessed Jesus, blessed Jesus
Thou hast bought us, Thine we are
Blessed Jesus, blessed Jesus
Thou hast bought us, Thine we are
We are Thine, do Thou befriend us
Be the Guardian of our way
Keep Thy flock, without, within
Jesus, Thou, the Lamb of God
Blessed Jesus, blessed Jesus
Hear, O hear us when we pray
Blessed Jesus, blessed Jesus
Hear, O hear us when we pray"""),
    song("430", "G", "Lead On, O King Eternal", """
Lead on, O King eternal
The day of march has come
Henceforth in fields of conquest
Thy tents shall be our home
Through days of preparation
Thy grace has made us strong
And now, O King eternal
We lift our battle song
Lead on, O King eternal
Till sin's fierce war shall cease
And holiness shall whisper
The sweet amen of peace
For not with swords loud clashing
Nor roll of stirring drums
With deeds of love and mercy
The heavenly kingdom comes"""),
    song("431", "F", "Reckless Love", """
Before I spoke a word, You were singing over me
You have been so, so good to me
Before I took a breath, You breathed Your life in me
You have been so, so kind to me
Chorus:
Oh, the overwhelming, never-ending, reckless love of God
Oh, it chases me down, fights 'til I'm found, leaves the ninety-nine
I couldn't earn it, and I don't deserve it, still You give Yourself away
Oh, the overwhelming, never-ending, reckless love of God
When I was Your foe, still Your love fought for me
You have been so, so good to me
When I felt no worth, You paid it all for me
You have been so, so kind to me"""),
    song("432", "C", "How He Loves", """
He is jealous for me
Loves like a hurricane, I am a tree
Bending beneath the weight of His wind and mercy
When all of a sudden I am unaware of
These afflictions eclipsed by glory
And I realize just how beautiful You are
And how great Your affections are for me
Chorus:
Oh, how He loves us, oh
How He loves us, how He loves us, oh
Oh, how He loves us, oh
How He loves us, how He loves us, oh
We are His portion and He is our prize
Drawn to redemption by the grace in His eyes
If grace is an ocean, we're all sinking
So heaven meets earth like an unforeseen kiss
And my heart turns violently inside of my chest
I don't have time to maintain these regrets
When I think about the way that He loves us"""),
    song("433", "C", "Cornerstone", """
My hope is built on nothing less
Than Jesus' blood and righteousness
I dare not trust the sweetest frame
But wholly trust in Jesus' name
Chorus:
Christ alone, cornerstone
Weak made strong in the Saviour's love
Through the storm He is Lord
Lord of all
When darkness seems to hide His face
I rest on His unchanging grace
In every high and stormy gale
My anchor holds within the veil
His oath, His covenant, His blood
Support me in the whelming flood
When all around my soul gives way
He then is all my hope and stay"""),
    song("434", "A", "Blessed Be Your Name", """
Blessed be Your name in the land that is plentiful
Where Your streams of abundance flow, blessed be Your name
Blessed be Your name when I'm found in the desert place
Though I walk through the wilderness, blessed be Your name
Chorus:
Every blessing You pour out, I'll turn back to praise
When the darkness closes in, Lord, still I will say
Blessed be the name of the Lord
Blessed be Your glorious name
Blessed be Your name when the sun's shining down on me
When the world's all as it should be, blessed be Your name
Blessed be Your name on the road marked with suffering
Though there's pain in the offering, blessed be Your name"""),
    song("435", "D", "Oceans (Where Feet May Fail)", """
You call me out upon the waters
The great unknown where feet may fail
And there I find You in the mystery
In oceans deep my faith will stand
Chorus:
And I will call upon Your name
And keep my eyes above the waves
When oceans rise, my soul will rest in Your embrace
For I am Yours and You are mine
Your grace abounds in deepest waters
Your sovereign hand will be my guide
Where feet may fail and fear surrounds me
You've never failed and You won't start now
Spirit lead me where my trust is without borders
Let me walk upon the waters
Wherever You would call me
Take me deeper than my feet could ever wander
And my faith will be made stronger
In the presence of my Saviour"""),
    song("436", "B", "Same God", """
I'm calling on the Holy Spirit
Almighty River come and fill me again
Come and fill me again
Come and fill me again
Chorus:
You are the same God
You are the same God
You are the same God, now as You were then
You are the same God
You are the same God
You are the same God, now as You were then
So pour out Your presence
As we worship and sing
You are the same God
You are the same God
You are the same God, now as You were then"""),
    song("437", "C", "Firm Foundation", """
Christ is my firm foundation
The rock on which I stand
When everything around me is shaken
I've never been more glad that I put my faith in Jesus
'Cause He's never let me down
He's never let me down
Chorus:
He's faithful through generations
So why would I doubt Him now?
He has never let me down
He has never let me down
Through every storm I've watched Him calm the thunder and lightning
He's faithful through generations
So why would I doubt Him now?
I've still got joy in chaos
I've got peace that makes no sense
So I won't be going under
Not when God is holding me now"""),
    song("438", "C", "Holy Forever", """
A thousand generations falling down in worship
To sing the song of ages to the Lamb
And all who've gone before us and all who will believe
Will sing the song of ages to the Lamb
Chorus:
Your name is the highest, Your name is the greatest
Your name stands above them all
All thrones and dominions, all powers and positions
Your name stands above them all
And the angels cry, holy
All creation cries, holy
You are lifted high, holy
Holy forever
If you've been forgiven and if you've been redeemed
Rise up and sing forever to the Lamb
If you walk in freedom and if you bear His name
Sing it evermore, ye saints, to the Lamb"""),
    song("439", "G", "I Thank God", """
Waking up every day
Blessed to be breathing
Knowing that You cover me
With grace that never ends
So I lay my head back down
And I lift my hands up high
Singing glory to the King
Of this awesome life
Chorus:
I thank God for the mountains, and I thank Him for the valleys
I thank Him for the storms He brought me through
'Cause if I'd never been through nothing
I wouldn't know to lean on You
So I thank God for the good days, and I thank Him for the bad
For the nights that found me brokenhearted
And the days that found me whole
For the ups and downs and in-betweens
For both the highs and lows
For everything that's brought me closer to Jesus
I thank God"""),
    song("440", "E", "No Longer Slaves", """
You unravel me with a melody
You surround me with a song
Of deliverance from my enemies
Till all my fears are gone
Chorus:
I'm no longer a slave to fear
I am a child of God
I'm no longer a slave to fear
I am a child of God
From my mother's womb You have chosen me
Love has called my name
I've been born again into Your family
Your blood flows through my veins
You split the sea so I could walk right through it
My fears were drowned in perfect love
You rescued me so I could stand and sing
I am a child of God"""),
    song("441", "G", "Raise a Hallelujah", """
I raise a hallelujah, in the middle of the mystery
I raise a hallelujah, fear you lost your hold on me
I'm gonna sing, in the middle of the storm
Louder and louder, you're gonna hear my praises roar
Up from the ashes, hope will arise
Death is defeated, the King is alive
Chorus:
I raise a hallelujah, I will watch the darkness flee
I raise a hallelujah, in the middle of the mystery
I raise a hallelujah, fear you lost your hold on me
I'm gonna sing, in the middle of the storm
Louder and louder, you're gonna hear my praises roar
Sing a little louder, sing a little louder
Sing a little louder, sing a little louder
Sing a little louder, sing a little louder
Sing a little louder"""),
    song("442", "C", "Graves Into Gardens", """
I searched the world but it couldn't fill me
Man's empty praise and treasures that fade
Are never enough
Then You came along and put me back together
And every desire is now satisfied here in Your love
Chorus:
Oh, there's nothing better than You
There's nothing better than You
Lord, there's nothing, nothing is better than You
I'm not afraid to show You my weakness
My failures and flaws, Lord, You've seen them all
You make me whole
I know Your love is the better way
'Cause the promise was fulfilled when You opened up the grave
I'll see You again, and You will call me home
And I will rise again, 'cause death has lost its hold on me"""),
    song("443", "G", "Battle Belongs", """
When all I see is the battle
You see my victory
When all I see is the mountain
You see a mountain moved
And as I walk through the shadow
Your love surrounds me
There's nothing to fear now
For I am safe with You
Chorus:
So when I fight, I'll fight on my knees
With my hands lifted high
Oh God, the battle belongs to You
And every fear I lay at Your feet
I'll sing through the night
Oh God, the battle belongs to You
You take what the enemy meant for evil
And You turn it for good
You turn it for good"""),
    song("444", "G", "Jireh", """
I'll never be more loved than I am right now
Wasn't holding You up so there's nothing I can do
To let You go
You don't need me but somehow You want me
Oh, how He loves me, how can it be?
Chorus:
Jehovah Jireh, You are more than enough for me
Jehovah Jireh, You provide and that is all I need
Jehovah Jireh, You are more than enough for me
Jehovah Jireh, You provide and that is all I need
You are my provider, my waymaker
My banner, my healer, my shepherd, my keeper
My portion forever, my strong tower
My refuge, my shelter, my fortress, my deliverer
My Saviour, my redeemer, my righteousness
My peace, my joy, my strength, my hope
My love, my life, my all in all"""),
    song("445", "G", "King of My Heart", """
Let the King of my heart be the mountain where I run
The fountain I drink from, oh He is my song
Let the King of my heart be the shadow where I hide
The ransom for my life, oh He is my song
Chorus:
You are good, good, oh
You are good, good, oh
You are good, good, oh
You are good, good, oh
Let the King of my heart be the wind inside my sails
The anchor in the waves, oh He is my song
Let the King of my heart be the fire inside my veins
The echo of my days, oh He is my song
You're never gonna let, never gonna let me down
You're never gonna let, never gonna let me down"""),
    song("446", "G", "My Lighthouse", """
In my wrestling and in my doubts
In my failures You won't walk out
Your great love will lead me through
You are the peace in my troubled sea
You are the peace in my troubled sea
Chorus:
In the silence, You won't let go
In the questions, Your truth will hold
Your great love will lead me through
You are the peace in my troubled sea
You are the peace in my troubled sea
My lighthouse, my lighthouse
Shining in the darkness, I will follow You
My lighthouse, my lighthouse
I will trust the promise You will carry me safe to shore"""),
    song("447", "G", "The Blessing", """
The Lord bless you and keep you
Make His face shine upon you and be gracious to you
The Lord turn His face toward you
And give you peace
Chorus:
Amen, amen, amen
May His favor be upon you and a thousand generations
And your family and your children and their children
May His presence go before you and behind you and beside you
All around you and within you
He is with you, He is with you
In the morning, in the evening
In your coming and your going
In your weeping and rejoicing
He is for you, He is for you"""),
    song("448", "G", "There Is None Like You", """
There is none like You
No one else can touch my heart like You do
I could search for all eternity long and find
There is none like You
Your mercy flows like a river wide
And healing comes from Your hand
Suffering children are safe in Your arms
There is none like You
There is none like You
No one else can touch my heart like You do
I could search for all eternity long and find
There is none like You"""),
    song("449", "G", "Your Grace Is Enough", """
Great is Your faithfulness, oh God
You wrestle with the sinner's heart
You lead us by still waters and to mercy
And nothing can keep us apart
So remember Your people, remember Your children
Remember Your promise, oh God
Chorus:
Your grace is enough for me
Your grace is enough for me
Your grace is enough for me
Your grace is enough for me
Your grace is enough
Heaven reaching down to us
Your grace is enough for me
Your grace is enough for me"""),
    song("450", "G", "You Are My All in All", """
You are my strength when I am weak
You are the treasure that I seek
You are my all in all
Seeking You as a precious jewel
Lord, to give up I'd be a fool
You are my all in all
Chorus:
Jesus, Lamb of God
Worthy is Your name
Jesus, Lamb of God
Worthy is Your name
Taking my sin, my cross, my shame
Rising again I bless Your name
You are my all in all
When I fall down You pick me up
When I am dry You fill my cup
You are my all in all"""),
    song("451", "G", "Amazing Love (You Are My King)", """
I'm forgiven because You were forsaken
I'm accepted, You were condemned
And I'm alive and well, Your spirit is within me
Because You died and rose again
Chorus:
Amazing love, how can it be
That You, my King, would die for me?
Amazing love, I know it's true
It's my joy to honor You
In all I do, I honor You
You are my King, You are my King
Jesus, You are my King
Jesus, You are my King"""),
    song("452", "G", "Lord I Lift Your Name on High", """
Lord, I lift Your name on high
Lord, I love to sing Your praises
I'm so glad You're in my life
I'm so glad You came to save us
Chorus:
You came from heaven to earth
To show the way
From the earth to the cross
My debt to pay
From the cross to the grave
From the grave to the sky
Lord, I lift Your name on high"""),
    song("453", "G", "Our God Is an Awesome God", """
When He rolls up His sleeves He ain't just putting on the ritz
Our God is an awesome God
There is thunder in His footsteps and lightning in His fists
Our God is an awesome God
And the Lord wasn't joking when He kicked 'em out of Eden
It wasn't for no reason that they shed His blood
His wrath and judgment wait, but His love is unrelenting
Our God is an awesome God
Chorus:
Our God is an awesome God
He reigns from heaven above
With wisdom, power, and love
Our God is an awesome God"""),
    song("454", "G", "Great Are You Lord", """
You give life, You are love
You bring light to the darkness
You give hope, You restore
Every heart that is broken
Great are You, Lord
Chorus:
It's Your breath in our lungs
So we pour out our praise
We pour out our praise
It's Your breath in our lungs
So we pour out our praise to You only
Great are You, Lord
All the earth will shout Your praise
Our hearts will cry, these bones will sing
Great are You, Lord"""),
    song("455", "G", "Forever", """
Give thanks to the Lord, our God and King
His love endures forever
For He is good, He is above all things
His love endures forever
Sing praise, sing praise
Chorus:
Forever God is faithful
Forever God is strong
Forever God is with us
Forever
From the rising to the setting sun
His love endures forever
By the Lamb slain for us
His love endures forever"""),
    song("456", "G", "Indescribable", """
From the highest of heights to the depths of the sea
Creation's revealing Your majesty
From the colors of fall to the fragrance of spring
Every creature unique in the song that it sings
All exclaiming
Chorus:
Indescribable, uncontainable
You placed the stars in the sky and You know them by name
You are amazing, God
All powerful, untameable
Awestruck we fall to our knees as we humbly proclaim
You are amazing, God
Who has told every lightning bolt where it should go
Or seen heavenly storehouses laden with snow
Who imagined the sun and gives source to its light
Yet conceals it to bring us the coolness of night
None can fathom"""),
    song("457", "A", "Hosanna", """
I see the King of glory coming on the clouds with fire
The whole earth shakes, the whole earth shakes
I see His love and mercy washing over all our sin
The people sing, the people sing
Chorus:
Hosanna, hosanna
Hosanna in the highest
Hosanna, hosanna
Hosanna in the highest
I see a generation rising up to take their place
With selfless faith, with selfless faith
I see a near revival stirring as we pray and seek
We're on our knees, we're on our knees
Heal my heart and make it clean
Open up my eyes to the things unseen
Show me how to love like You have loved me
Break my heart for what breaks Yours
Everything I am for Your kingdom's cause
As I walk from earth into eternity"""),
    song("458", "G", "Lead Me to the Cross", """
Saviour, I come quiet my soul
Remember redemption's hill
Where Your blood was spilled for my ransom
Chorus:
Everything I once held dear
I count it all as lost
Lead me to the cross where Your love poured out
Bring me to my knees, Lord, I lay me down
Rid me of myself, I belong to You
Oh, lead me, lead me to the cross
You were as I, tired and tempted
And the world can't see how hard You tried
But Your Father called You to His side
And both arms opened wide"""),
    song("459", "G", "The Heart of Worship", """
When the music fades, all is stripped away
And I simply come
Longing just to bring something that's of worth
That will bless Your heart
I'll bring You more than a song
For a song in itself is not what You have required
You search much deeper within
Through the way things appear
You're looking into my heart
Chorus:
I'm coming back to the heart of worship
And it's all about You, it's all about You, Jesus
I'm sorry, Lord, for the thing I've made it
When it's all about You, it's all about You, Jesus"""),
    song("460", "C", "Whom Shall I Fear (God of Angel Armies)", """
You hear me when I call
You are my morning song
Though darkness fills the night
It cannot hide the light
Whom shall I fear?
Chorus:
I know who goes before me
I know who stands behind
The God of angel armies is always by my side
The one who reigns forever
He is a friend of mine
The God of angel armies is always by my side
My strength is in Your name
For You alone defend me
You crush my enemies
Whom shall I fear?
Nothing formed against me shall stand
You hold the victory
You are my shield and song
My God, who reigns forever"""),
    song("461", "G", "This Is Amazing Grace", """
Who breaks the power of sin and darkness
Whose love is mighty and so much stronger
The King of glory, the King above all kings
Who shakes the whole earth with holy thunder
And leaves us breathless in awe and wonder
The King of glory, the King above all kings
Chorus:
This is amazing grace
This is unfailing love
That You would take my place
That You would bear my cross
You lay down Your life
That I would be set free
Oh, Jesus, I sing for all that You've done for me
Who brings our chaos back into order
Who makes the orphan a son and daughter
The King of glory, the King above all kings"""),
    song("462", "G", "We Fall Down", """
We fall down, we lay our crowns
At the feet of Jesus
The greatness of mercy and love
At the feet of Jesus
And we cry holy, holy, holy
And we cry holy, holy, holy
And we cry holy, holy, holy
Is the Lamb
We fall down, we lay our crowns
At the feet of Jesus
The greatness of mercy and love
At the feet of Jesus"""),
    song("463", "G", "Bind Us Together", """
Bind us together, Lord
Bind us together with cords that cannot be broken
Bind us together, Lord
Bind us together with love
There is only one God, there is only one King
There is only one body, that is why we sing
Bind us together, Lord
Bind us together with love"""),
    song("464", "G", "Everlasting God", """
Strength will rise as we wait upon the Lord
We will wait upon the Lord, we will wait upon the Lord
Strength will rise as we wait upon the Lord
We will wait upon the Lord, we will wait upon the Lord
Chorus:
Our God, You reign forever
Our hope, our strong deliverer
You are the everlasting God
The everlasting God
You do not faint, You won't grow weary
You're the defender of the weak
You comfort those in need
You lift us up on wings like eagles"""),
    song("465", "C", "God of Wonders", """
Lord of all creation of water, earth, and sky
The heavens are Your tabernacle
Glory to the Lord on high
Chorus:
God of wonders beyond our galaxy
You are holy, holy
The universe declares Your majesty
You are holy, holy
Lord of heaven and earth
Lord of heaven and earth
Early in the morning I will celebrate the light
When I stumble in the darkness I will call Your name by night
Hallelujah to the Lord of heaven and earth
Hallelujah to the Lord of heaven and earth"""),
    song("466", "G", "Here I Am, Lord", """
I, the Lord of sea and sky
I have heard My people cry
All who dwell in dark and sin
My hand will save
I, who made the stars of night
I will make their darkness bright
Who will bear My light to them?
Whom shall I send?
Chorus:
Here I am, Lord
Is it I, Lord?
I have heard You calling in the night
I will go, Lord, if You lead me
I will hold Your people in my heart
I, the Lord of snow and rain
I have borne my people's pain
I have wept for love of them
They turn away
I will break their hearts of stone
Give them hearts for love alone
I will speak My word to them
Whom shall I send?"""),
    song("467", "G", "Breathe", """
This is the air I breathe
This is the air I breathe
Your holy presence living in me
This is my daily bread
This is my daily bread
Your very word spoken to me
Chorus:
And I, I'm desperate for You
And I, I'm lost without You
This is the air I breathe
This is the air I breathe
Your holy presence living in me"""),
    song("468", "G", "Shine Jesus Shine", """
Lord, the light of Your love is shining
In the midst of the darkness, shining
Jesus, light of the world, shine upon us
Set us free by the truth You now bring us
Shine on me, shine on me
Chorus:
Shine, Jesus, shine
Fill this land with the Father's glory
Blaze, Spirit, blaze
Set our hearts on fire
Flow, river, flow
Flood the nations with grace and mercy
Send forth Your word
Lord, and let there be light"""),
    song("469", "G", "They'll Know We Are Christians", """
We are one in the Spirit, we are one in the Lord
We are one in the Spirit, we are one in the Lord
And we pray that all unity may one day be restored
And they'll know we are Christians by our love, by our love
Yes, they'll know we are Christians by our love
We will walk with each other, we will walk hand in hand
We will walk with each other, we will walk hand in hand
And together we'll spread the news that God is in our land
And they'll know we are Christians by our love, by our love
Yes, they'll know we are Christians by our love
We will work with each other, we will work side by side
We will work with each other, we will work side by side
And we'll guard each one's dignity and save each one's pride
And they'll know we are Christians by our love, by our love
Yes, they'll know we are Christians by our love"""),
    song("470", "G", "Trading My Sorrows", """
I'm trading my sorrows
I'm trading my shame
I'm laying them down for the joy of the Lord
I'm trading my sickness
I'm trading my pain
I'm laying them down for the joy of the Lord
Chorus:
Yes Lord, yes Lord, yes yes Lord
Yes Lord, yes Lord, yes yes Lord
Amen, amen, amen
We say yes Lord, yes Lord, yes yes Lord
Yes Lord, yes Lord, yes yes Lord
Amen, amen, amen"""),
    song("471", "G", "Thy Word", """
Thy Word is a lamp unto my feet
And a light unto my path
Thy Word is a lamp unto my feet
And a light unto my path
When I feel afraid, think I've lost my way
Still You're there right beside me
And nothing will I fear as long as You are near
Please be near me to the end
I will not forget Your love for me and yet
My heart forever is wandering
Jesus be my guide and hold me to Your side
And I will love You to the end"""),
    song("472", "G", "Wonderful Merciful Savior", """
Wonderful, merciful Savior
Precious Redeemer and Friend
Who would have thought that a Lamb could
Rescue the souls of men?
Oh, You rescue the souls of men
Chorus:
You are the One that we praise
You are the One we adore
You give the healing and grace our hearts always hunger for
Oh, our hearts always hunger for
Counselor, Comforter, Keeper
Spirit we long to embrace
You offer hope when our hearts have
Hopelessly lost the way
Oh, we've hopelessly lost the way"""),
    song("473", "G", "Yes I Will", """
I count on one thing
The same God who never fails
Will not fail me now
You won't fail me now
In the waiting
The same God who's never late
Is working all things out
You're working all things out
Chorus:
Yes I will, lift You high in the lowest valley
Yes I will, bless Your name
Yes I will, sing for joy when my heart is heavy
All my days, yes I will
I choose to praise to silence fear
I won't forget the power of Jesus' name"""),
    song("474", "G", "Your Name", """
As morning dawns and evening fades
You inspire songs of praise
That rise from earth to touch Your heart
And glorify Your name
Chorus:
Your name is a strong and mighty tower
Your name is a shelter like no other
Your name, let the nations sing it louder
'Cause nothing has the power to save
But Your name
Jesus, in Your name we pray
Come and fill our hearts today
Lord, give us strength to live for You
And glorify Your name"""),
    song("475", "G", "Your Love Never Fails", """
Nothing can separate
Even if I ran away
Your love never fails
I know I still make mistakes
But You have new mercies for me everyday
Your love never fails
Chorus:
You stay the same through the ages
Your love never changes
There may be pain in the night but joy comes in the morning
And when the oceans rage, I don't have to be afraid
Because I know that You love me
Your love never fails
The wind is strong and the water's deep
But I'm not alone in these open seas
'Cause Your love never fails
The chasm is far too wide
I never thought I'd reach the other side
But Your love never fails"""),
    song("476", "G", "How Deep the Father's Love for Us", """
How deep the Father's love for us
How vast beyond all measure
That He should give His only Son
To make a wretch His treasure
How great the pain of searing loss
The Father turns His face away
As wounds which mar the Chosen One
Bring many sons to glory
Behold the man upon a cross
My sin upon His shoulders
Ashamed, I hear my mocking voice
Call out among the scoffers
It was my sin that held Him there
Until it was accomplished
His dying breath has brought me life
I know that it is finished"""),
    song("477", "G", "Forever Reign", """
You are good, You are good
When there's nothing good in me
You are love, You are love
On display for all to see
You are light, You are light
When the darkness closes in
You are hope, You are hope
You have covered all my sin
Chorus:
Oh, I'm running to Your arms
The riches of Your love will always be enough
Nothing compares to Your embrace
Light of the world forever reign
Oh, I'm running to Your arms
The riches of Your love will always be enough
Nothing compares to Your embrace
Light of the world forever reign"""),
    song("478", "G", "From the Inside Out", """
A thousand times I've failed
Still Your mercy remains
And should I stumble again
Still You've got me covered
Through it all, You never change
At Your name, the mountains shake
And at Your name, the oceans roar
All creation knows You now
And every knee will bow
Chorus:
From the inside out, Lord, my soul cries out
Lord, I need You, oh, I need You
Every hour I need You
My one and only Jesus, my everything
My one and only Jesus"""),
    song("479", "G", "Give Thanks", """
Give thanks with a grateful heart
Give thanks to the Holy One
Give thanks because He's given Jesus Christ, His Son
Chorus:
And now let the weak say I am strong
Let the poor say I am rich
Because of what the Lord has done for us
Give thanks with a grateful heart
Give thanks to the Holy One
Give thanks because He's given Jesus Christ, His Son
Give thanks because He's given Jesus Christ, His Son"""),
    song("480", "G", "He Is Exalted", """
He is exalted, the King is exalted on high
I will praise Him
He is exalted forever exalted
And I will praise His name
He is the Lord
Forever His truth shall reign
Heaven and earth rejoice in His holy name
He is exalted, the King is exalted on high"""),
    song("481", "G", "He Is Lord", """
He is Lord, He is Lord
He is risen from the dead and He is Lord
Every knee shall bow, every tongue confess
That Jesus Christ is Lord
He is King, He is King
He will draw all nations to Him, He is King
And the time shall be when the world shall sing
That Jesus Christ is King"""),
    song("482", "G", "Holy Spirit", """
There's nothing worth more that will ever come close
No thing can compare, You're our living hope
Your presence, Lord
I've tasted and seen of the sweetest of loves
Where my heart becomes free and my shame is undone
Your presence, Lord
Chorus:
Holy Spirit, You are welcome here
Come flood this place and fill the atmosphere
Your glory, God, is what our hearts long for
To be overcome by Your presence, Lord
Let us become more aware of Your presence
Let us experience the glory of Your goodness"""),
    song("483", "G", "I Will Rise", """
There's a peace I've come to know
Though my heart and flesh may fail
There's an anchor for my soul
I can say, it is well
Jesus has overcome
And the grave is overwhelmed
The victory is won
He is risen from the dead
Chorus:
I will rise when He calls my name
No more sorrow, no more pain
I will rise on eagle's wings
Before my God fall on my knees
And rise, I will rise
The giver of life is stirring within
The spark eternal won't be dimmed
He brands the fear upon His heart
Perfect love that never ends"""),
    song("484", "G", "I Will Trust in You", """
Let me find You in the valley
Let me find You in the fire
In the storm, You are my shelter
You're my only desire
Chorus:
I will trust in You
I will trust in You
Let this broken vessel do
What overflows from You
You are my strength and shield
Though the battle rages on
You are my hiding place
Till the storm is gone
I will trust in You"""),
    song("485", "G", "Love Came Down", """
If my heart is overwhelmed
And I cannot see Your plan
When my weary mind is worn out
I will trust You and obey
Chorus:
Love came down and rescued me
Love came down and set me free
I am Yours, Lord, I'm forever Yours
Mountains high or valley low
I sing wherever I go
I am Yours, Lord, I'm forever Yours
You are God, You are good
You are everything to me
You are God, You are good
You are everything to me"""),
    song("486", "G", "Made Me Glad", """
I will trust in You
I will trust in You
I will trust in You
Say of Your love, only say of Your love
That it is strong as the world the Lord has made
I will fear no evil, for You are with me
And I will dwell in the house of the Lord forever
Chorus:
You are my shield, my strength
My portion, deliverer
My shelter, strong tower
My very present help in time of need"""),
    song("487", "G", "Majestic", """
Majestic, Lord, we worship Your majesty
Unto King of kings, Lord of lords
Majestic, we worship Your majesty
Jesus, our King, we bow before Thee
Chorus:
Majestic, holy is Your name
Majestic, heaven and earth proclaim
Majestic, holy is Your name
Majestic, heaven and earth proclaim
Majestic, Lord, we worship Your majesty
Unto King of kings, Lord of lords
Majestic, we worship Your majesty
Jesus, our King, we bow before Thee"""),
    song("488", "G", "My Chains Are Gone (Amazing Grace)", """
Amazing grace, how sweet the sound
That saved a wretch like me
I once was lost, but now am found
Was blind, but now I see
Chorus:
My chains are gone, I've been set free
My God, my Saviour has ransomed me
And like a flood His mercy reigns
Unending love, amazing grace
The Lord has promised good to me
His word my hope secures
He will my shield and portion be
As long as life endures"""),
    song("489", "G", "My Redeemer Lives", """
Who taught the sun where to stand in the morning
And who taught the ocean you can only come this far
And who showed the moon where to hide till evening
Whose words alone can catch a falling star
Chorus:
Well I know my Redeemer lives
I know my Redeemer lives
Let all creation testify
Let this life within me cry
I know my Redeemer lives
The very earth that blooms beneath my feet
Has been resurrected every spring
And every seed that grows within the valley
Has been buried once and born again"""),
    song("490", "G", "One Way", """
Standing in Your presence, Lord
I offer You my heart
Jesus, I am open
For You to have Your way in me
Chorus:
One way, Jesus
You're the only one that I could live for
One way, Jesus
You're the only one that I could die for
One way, Jesus
You're the only one that I could live for
One way, Jesus
You're the only one that I could die for
I live to worship You"""),
    song("491", "G", "Our God", """
Water You turned into wine
Opened the eyes of the blind
There's no one like You, none like You
Into the darkness You shine
Out of the ashes we rise
There's no one like You, none like You
Chorus:
Our God is greater, our God is stronger
God You are higher than any other
Our God is Healer, awesome in power
Our God, our God
And if our God is for us, then who could ever stop us?
And if our God is with us, then what could stand against?"""),
    song("492", "G", "Overcome", """
Worthy is the Lamb, seated on the throne
Crown You now with many crowns
You rule forevermore
Lift it up, we lift it up
Chorus:
Overcome, overcome
Overcome, overcome
Heaven's gates unfold, we have overcome
Overcome, overcome
Overcome, overcome
Heaven's gates unfold, we have overcome
Worthy is the Lamb, worthy is the Lamb
Worthy is the Lamb, worthy is the Lamb
Worthy is the Lamb, seated on the throne
Crown You now with many crowns
You rule forevermore"""),
    song("493", "G", "Sing to the King", """
Sing to the King who is coming to reign
Glory to Jesus, the Lamb that was slain
Life and salvation His empire shall bring
And joy to the nations when Jesus is King
Chorus:
Come, let us sing a song, a song declaring that we belong to Jesus
He is all we need
Lift up a heart of praise, sing now with voices raised to Jesus
Sing to the King
For His returning we watch and we pray
We will be ready the dawn of that day
We'll sing for the King who is coming to reign
Sing to the King"""),
    song("494", "G", "Spirit Break Out", """
Spirit break out, break our walls down
Spirit break out, heaven come down
Chorus:
Kingdom come, make Your name known
Kingdom come, have Your own way
Spirit break out, break our walls down
Spirit break out, heaven come down
Our Father, all of heaven roars Your name
Let all creation sound the same
Oh, let it be Jesus' name
As we lift up Your praise
Fill this place, fill this place"""),
    song("495", "G", "Surely the Presence of the Lord", """
Surely the presence of the Lord is in this place
I can feel His mighty power and His grace
I can hear the brush of angels' wings
I see glory on each face
Surely the presence of the Lord is in this place
In the midst of His children the Lord has said He would be
It doesn't take very long till where His children gather
That's where He'll be
And I'm glad that I know there's a refuge I can claim
Just to linger in the shadow of His name
Surely the presence of the Lord is in this place"""),
    song("496", "G", "The Wonderful Cross", """
When I survey the wondrous cross
On which the Prince of glory died
My richest gain I count but loss
And pour contempt on all my pride
Chorus:
Oh, the wonderful cross, oh, the wonderful cross
Bids me come and die and find that I may truly live
Oh, the wonderful cross, oh, the wonderful cross
All who gather round the hallowed ground
Where heaven's love and justice meet
See from His head, His hands, His feet
Sorrow and love flow mingled down
Did e'er such love and sorrow meet
Or thorns compose so rich a crown?"""),
    song("497", "G", "Worthy of Your Praise", """
I will worship with all of my heart
I will praise You with all of my strength
I will seek You all of my days
I will follow all of Your ways
Chorus:
I will give You all my worship
I will give You all my praise
You alone I long to worship
You alone are worthy of my praise
I will bow down and hail You as King
I will serve You, give You everything
I will lift up my eyes to Your throne
I will trust You, I will trust You alone"""),
    song("498", "G", "Scandal of Grace", """
Grace, what have You done?
Murdered for me on that cross
Accused in absence of wrong
My sin washed away in Your blood
Chorus:
Too much to make sense of it all
I know that Your love breaks my fall
The scandal of grace, You died in my place
My enemy, God, was murdered for me
Grace, all sin no more
Shame has no place in Your presence
Crowned with salvation and songs
Of everlasting praise
Oh, the scandal of grace
You were there in my shame
You were there in my chains
You were there in the dark
You were there in the fire
You were there in the grave
You were there in the night
You were there in the fight
You were there all the time"""),
    song("499", "G", "So Will I (100 Billion X)", """
God of creation, there at the start before the beginning of time
With no point of reference, You spoke to the dark and fleshed out the wonder of light
And as You speak, a hundred billion galaxies are born
In the vapor of Your breath the planets form
If the stars were made to worship so will I
I can see Your heart in everything You've made
Every burning star, a signal fire of grace
If creation sings Your praises so will I
Chorus:
So will I, I will worship like a symphony
You alone deserve my everything
If the oceans roar Your greatness so will I
For if everything exists to lift You high so will I
If the wind goes where You send it so will I
If You left the grave behind You so will I
I can see Your heart in everything You've done
Every painting breathed by You, every creature formed by love
If the stars were made to worship so will I"""),
    song("500", "G", "Surrounded (Fight My Battles)", """
This is how I fight my battles
This is how I fight my battles
This is how I fight my battles
This is how I fight my battles
It may look like I'm surrounded but I'm surrounded by You
This is how I fight my battles
This is how I fight my battles
This is how I fight my battles
This is how I fight my battles
This is how I fight my battles
This is how I fight my battles
It may look like I'm surrounded but I'm surrounded by You"""),
    song("501", "G", "Ancient Words", """
Holy words long preserved for our walk in this world
They resound with God's own heart
Oh, let the ancient words impart
Chorus:
Ancient words, ever true, changing me and changing you
We have come with open hearts, oh let the ancient words impart
Words of life, words of hope, give us strength, help us cope
In this world where e'er we roam, ancient words will guide us home
Holy words of our faith, handed down to this age
Came to us through sacrifice, oh heed the faithful words of Christ"""),
    song("502", "G", "Better Is One Day", """
How lovely is Your dwelling place
O Lord Almighty
My soul longs and even faints for the courts of the Lord
My heart and flesh cry out for the living God
Chorus:
Better is one day in Your courts
Better is one day in Your house
Better is one day in Your courts than thousands elsewhere
One thing I ask and I would seek
To dwell in the house of the Lord all my days
To gaze upon the beauty of the Lord and to seek Him in His temple"""),
    song("503", "G", "Days of Elijah", """
These are the days of Elijah
Declaring the word of the Lord
And these are the days of Your servant Moses
Righteousness being restored
And though these are days of great trial
Of famine and darkness and sword
Still we are the voice in the desert crying
Prepare ye the way of the Lord
Chorus:
Behold He comes, riding on the clouds
Shining like the sun at the trumpet call
Lift your voice, it's the year of jubilee
And out of Zion's hill salvation comes
These are the days of Ezekiel
The dry bones becoming as flesh
And these are the days of Your servant David
Rebuilding a temple of praise"""),
    song("504", "G", "Draw Me Close", """
Draw me close to You, never let me go
I lay it all down again to hear You say that I'm Your friend
You are my desire, no one else will do
'Cause nothing else could take Your place
To feel the warmth of Your embrace
Help me find the way, bring me back to You
Chorus:
You're all I want, You're all I've ever needed
You're all I want, help me know You are near"""),
    song("505", "G", "Friend of God", """
Who am I that You are mindful of me
That You hear me when I call
Is it true that You are thinking of me
How You love me, it's amazing
Chorus:
I am a friend of God, I am a friend of God
I am a friend of God, He calls me friend
God almighty, Lord of glory
You have called me friend
Who am I that You are mindful of me
That You hear me when I call
Is it true that You are thinking of me
How You love me, it's amazing"""),
    song("506", "G", "Give Us Clean Hands", """
We bow our hearts, we bend our knees
O Spirit, come make us humble
We turn our eyes from evil things
O Lord, we cast down our idols
Chorus:
Give us clean hands, give us pure hearts
Let us not lift our souls to another
O God, let us be a generation that seeks
That seeks Your face, O God of Jacob
O God, let us be a generation that seeks
That seeks Your face, O God of Jacob"""),
    song("507", "G", "Glorious Day", """
I was buried beneath my shame
Who could carry that kind of weight?
It was my tomb till I met You
I was breathing but not alive
All my failures I tried to hide
It was my tomb till I met You
Chorus:
You called my name and I ran out of that grave
Out of the darkness into Your glorious day
You called my name and I ran out of that grave
Breath into my bones, let me come alive
By Your grace I rise
Yesterday's gone and today I'm alive
'Cause You called my name, called my name
I needed rescue, my sin was heavy
But chains break at the weight of Your glory"""),
    song("508", "G", "God Is Able", """
God is able, He will never fail
He is almighty God
Greater things have yet to come
And greater things are still to be done in this city
Greater things have yet to come
And greater things are still to be done here
Chorus:
God is able, He will never fail
He is almighty God
Greater things have yet to come
And greater things are still to be done in this city
Greater things have yet to come
And greater things are still to be done here
We believe in You, God, we believe in You
Let faith arise in us, let faith arise"""),
    song("509", "G", "He Reigns", """
It's the song of the redeemed rising from the African plain
It's the song of the forgiven drowning out the Amazon rain
The song of Asian believers filled with God's holy fire
It's every tribe, every tongue, every nation, a love song born of a grateful choir
Chorus:
And it's all God's children singing glory, glory, hallelujah
He reigns, He reigns
It's all God's children singing glory, glory, hallelujah
He reigns, He reigns
Let all God's people sing it
A holy symphony of the saved, the earth and the heavens sing
He reigns, He reigns"""),
    song("510", "G", "Hungry (Falling on My Knees)", """
Hungry, I come to You for I know You satisfy
I am empty but I know Your love does not run dry
So I wait for You, so I wait for You
Chorus:
I'm falling on my knees
Offering all of me
Jesus, You're all this heart is living for
Broken, I run to You for Your arms are open wide
I am weary but I know Your touch restores my life
So I wait for You, so I wait for You"""),
    song("511", "G", "I Could Sing of Your Love Forever", """
Over the mountains and the sea
Your river runs with love for me
And I will open up my heart
And let the Healer set me free
I'm happy to be in the truth
And I will daily lift my hands
For I will always sing of when Your love came down
Chorus:
I could sing of Your love forever
I could sing of Your love forever
I could sing of Your love forever
I could sing of Your love forever
Oh, I feel like dancing
It's foolishness I know
But when the world has seen the light
Shall come back as ones we know"""),
    song("512", "G", "I Stand in Awe", """
You are beautiful beyond description
Too marvelous for words
Too wonderful for comprehension
Like nothing ever seen or heard
Who can grasp Your infinite wisdom?
Who can fathom the depth of Your love?
You are beautiful beyond description
Majesty, enthroned above
Chorus:
And I stand, I stand in awe of You
I stand, I stand in awe of You
Holy God, to You, holy God, to You
I stand in awe of You"""),
    song("513", "G", "I Will Celebrate", """
I will celebrate, sing unto the Lord
Sing to the Lord a new song
I will celebrate, sing unto the Lord
Sing to the Lord a new song
Chorus:
I will celebrate, sing unto the Lord
Sing to the Lord a new song
I will celebrate, sing unto the Lord
Sing to the Lord a new song
Sing to the Lord, all the earth
Sing to the Lord, bless His name
Tell of His salvation from day to day
Declare His glory among the nations
His marvelous works among all the peoples"""),
    song("514", "G", "Jesus, Name Above All Names", """
Jesus, name above all names
Beautiful Saviour, glorious Lord
Emmanuel, God is with us
Blessed Redeemer, living Word
Jesus, name above all names
Beautiful Saviour, glorious Lord
Emmanuel, God is with us
Blessed Redeemer, living Word"""),
    song("515", "G", "Joy of the Lord", """
I've got the joy, joy, joy, joy down in my heart
Where? Down in my heart
Where? Down in my heart
I've got the joy, joy, joy, joy down in my heart
Where? Down in my heart to stay
Chorus:
And I'm so happy, so very happy
I've got the love of Jesus in my heart
And I'm so happy, so very happy
I've got the love of Jesus in my heart
I've got the peace that passes understanding down in my heart
I've got the love of Jesus, love of Jesus down in my heart
I've got that wonderful, wonderful Spirit down in my heart
I've got the wonderful love of my blessed Redeemer way down in the depths of my heart"""),
    song("516", "G", "Let Everything That Has Breath", """
Let everything that, everything that
Everything that has breath praise the Lord
Let everything that, everything that
Everything that has breath praise the Lord
Chorus:
Praise You in the morning, praise You in the evening
Praise You when I'm young and when I'm old
Praise You when I'm laughing, praise You when I'm grieving
Praise You every season of the soul
If we could see how much You're worth
Your power, Your might, Your endless love
Then surely we would never cease to praise
Let everything that has breath praise the Lord"""),
    song("517", "G", "Lord You Have My Heart", """
Lord, You have my heart
And I will search for Yours, Jesus, take my life and lead me on
Lord, You have my heart
And I will search for Yours, Jesus, take my life and lead me on
Chorus:
Holy Spirit, come transform us
Till we look like Jesus
Holy Spirit, come transform us
Till we look like Jesus
Till we look like Jesus
Spirit of the living God, come make Your presence known
Come breathe Your life into our souls
Spirit of the living God, come make Your presence known
Come breathe Your life into our souls"""),
    song("518", "G", "Made For More", """
I know who I am because I know who You are
You have always been the same, You will never change
You have always been the same, You will never change
Chorus:
I was made for more than this
I was made for more than this
I was made for more than this
I was made for more than this
I was made for more than this
I was made for more than this
I was made for more than this
I was made for more than this
You are the God who was, who is, and is to come
You are the God who was, who is, and is to come"""),
    song("519", "G", "Once Again", """
Jesus Christ, I think upon Your sacrifice
You became nothing, poured out to death
Many times I've wondered at Your gift of life
And I'm in that place once again
And I'm in that place once again
Chorus:
Once again I look upon the cross where You died
Humility comes rushing in, in this holy place
And once again I am amazed at Your great love
And I'm humbled by Your majesty
And once again I look upon the cross where You died
And once again I am amazed at Your great love"""),
    song("520", "G", "Only Hope", """
You are my only hope
You're my only prayer
So I look to You alone
You are my only hope
You're my only prayer
So I look to You alone
Chorus:
My eyes are on You, Lord
My eyes are on You
My eyes are on You, Lord
My eyes are on You
In You I find my rest
In You I find my strength
In You I find my hope
In You I find my peace"""),
    song("521", "G", "Open the Floodgates of Heaven", """
Open the floodgates of heaven
We want to see You, Lord
Open the floodgates of heaven
We want to see You, Lord
Chorus:
Let it rain, let it rain
Open the floodgates of heaven
Let it rain, let it rain
Open the floodgates of heaven
We need Your presence, Lord
We need Your presence, Lord
Open the floodgates of heaven
We want to see You, Lord"""),
    song("522", "G", "Praise You in This Storm", """
I was sure by now God You would have reached down
And wiped our tears away, stepped in and saved the day
But once again, I say amen that it's still raining
As the thunder rolls I barely hear Your whisper through the rain
I'm untouched by pain, I'm not alone
Chorus:
And I'll praise You in this storm
And I will lift my hands
For You are who You are
No matter where I am
And every tear I've cried
You hold in Your hand
You never left my side
And though my heart is torn
I will praise You in this storm"""),
    song("523", "G", "Refuge", """
You are my refuge, my shelter in the storm
You are my anchor, my hope is in Your name
When the waves rise, I will not be afraid
You are my refuge, my shelter in the storm
Chorus:
I will trust in You, I will trust in You
Let this broken vessel do what overflows from You
You are my strength and shield
Though the battle rages on
You are my hiding place
Till the storm is gone"""),
    song("524", "G", "Run to the Father", """
I've carried a burden for too long on my own
I wasn't created to bear You alone
I fell but You have raised me up again
You've been faithful when I was faithless
Chorus:
So I run to the Father again and again and again
And I run to the Father again and again and again
'Cause You're the God of forgiveness and mercy and grace
And I run to the Father again and again and again
My sin is heavy but Your love is stronger
My shame is deep but Your grace is deeper
My past is dark but Your future's brighter
My guilt is strong but Your mercy's greater"""),
    song("525", "G", "Seek Ye First", """
Seek ye first the kingdom of God
And His righteousness
And all these things shall be added unto you
Hallelujah, hallelujah
Chorus:
Ask and it shall be given unto you
Seek and ye shall find
Knock and the door shall be opened unto you
Hallelujah, hallelujah
Man shall not live by bread alone
But by every word
That proceeds out of the mouth of God
Hallelujah, hallelujah"""),
    song("526", "G", "Show Me Your Glory", """
I see Your face in every sunrise
The colors of the morning are inside Your eyes
The world awakens in the light of the day
I look up to the sky and say
Chorus:
Show me Your glory, show me Your majesty
Show me Your glory, show me Your holiness
Show me Your glory, show me Your power
Show me Your glory, Lord
I long to look on the face of the One that I love
Long to stay in Your presence, it's where I belong
Show me Your glory, show me Your glory, Lord"""),
    song("527", "G", "Step by Step", """
And I will praise You, yes, I will praise You
For every blessing You pour out
I will turn back to praise
When the darkness veils His lovely face
I rest on His unchanging grace
In every high and stormy gale
My anchor holds within the veil
Chorus:
Step by step, You lead me
And I will follow You all of my days
Step by step, You lead me
And I will follow You all of my days
You are my guide, You are my strength
You are my hope, You are my song"""),
    song("528", "G", "Thank You Jesus for the Blood", """
Thank You Jesus for the blood applied
Thank You Jesus it has washed me white
Thank You Jesus, You have saved my life
Brought me from the darkness into light
Chorus:
Thank You Jesus for the blood applied
Thank You Jesus it has washed me white
Thank You Jesus, You have saved my life
Brought me from the darkness into light
I was lost but now I'm found
I was blind but now I see
I was dead but now I live
Because You died for me"""),
    song("529", "G", "Through It All", """
I've had many tears and sorrows
I've had questions for tomorrow
There've been times I didn't know right from wrong
But in every situation God gave blessed consolation
That my trials come to only make me strong
Chorus:
Through it all, through it all
I've learned to trust in Jesus
I've learned to trust in God
Through it all, through it all
I've learned to depend upon His Word
I've been to lots of places
I've seen a lot of faces
There's been times I felt so all alone
But in my lonely hours, yes, those precious lonely hours
Jesus let me know that I was His own"""),
    song("530", "G", "We Want to See Jesus Lifted High", """
We want to see Jesus lifted high
A banner that flies across the land
That all men might see the truth and know
He is the way to heaven
Chorus:
We want to see, we want to see
We want to see Jesus lifted high
We want to see, we want to see
We want to see Jesus lifted high
We want to see Jesus lifted high
A banner that flies across the land
That all men might see the truth and know
He is the way to heaven"""),
    song("531", "G", "Welcome Into This Place", """
Welcome into this place
Welcome into this broken vessel
You desire to abide in the praises of Your people
So we lift our hands and we lift our hearts
As we offer up this praise unto Your name
Chorus:
Welcome into this place
Welcome into this broken vessel
You desire to abide in the praises of Your people
So we lift our hands and we lift our hearts
As we offer up this praise unto Your name
Lord, we welcome You"""),
    song("532", "G", "When the Spirit of the Lord", """
When the Spirit of the Lord moves in this place
The atmosphere will change
When the Spirit of the Lord moves in this place
The atmosphere will change
Chorus:
And everything will change
When the Spirit of the Lord moves in this place
And everything will change
When the Spirit of the Lord moves in this place
We will see Your glory
We will see Your power
We will see Your presence in this place"""),
    song("533", "G", "You Are Good", """
Lord, You are good and Your mercy endureth forever
People from every nation and tongue
From generation to generation
Chorus:
We worship You, hallelujah, hallelujah
We worship You for who You are
We worship You, hallelujah, hallelujah
We worship You for who You are and You are good
Lord, You are good and Your mercy endureth forever
People from every nation and tongue
From generation to generation"""),
    song("534", "G", "You Are My Hiding Place", """
You are my hiding place
You always fill my heart with songs of deliverance
Whenever I am afraid I will trust in You
I will trust in You
Let the weak say I am strong in the strength of the Lord
Chorus:
You are my hiding place
You always fill my heart with songs of deliverance
Whenever I am afraid I will trust in You
I will trust in You
Let the weak say I am strong in the strength of the Lord
You are my hiding place, You are my hiding place"""),
    song("535", "G", "You Are Worthy", """
You are worthy, You are worthy
You are worthy, Lord
You are worthy, You are worthy
You are worthy, Lord
Chorus:
Worthy is the Lamb that was slain
Worthy is the Lamb that was slain
Worthy is the Lamb that was slain
To receive power and riches and wisdom and strength
And honor and glory and blessing
You are worthy, You are worthy
You are worthy, Lord"""),
    song("536", "G", "Desert Song", """
This is my prayer in the desert
When all that's within me feels dry
This is my prayer in my hunger and need
My God is the God who provides
Chorus:
And I will bring praise, I will bring praise
No matter what the desert brings
I will bring praise, I will bring praise
No matter what the desert brings
This is my prayer in the fire
In weakness or trial or pain
There is a faith proved of more worth than gold
So refine me through the flames"""),
    song("537", "G", "Famous One", """
You are the Lord, the Famous One, famous One
Great is Your name in all the earth
Let us sing of Your love and mercy
Let us sing of Your love and mercy
Chorus:
You are the Lord, the Famous One, famous One
Great is Your name in all the earth
The heavens declare You're glorious, glorious
Great is Your fame beyond the earth
And for all You've done and yet to do
With every breath I'm praising You
There is no one like You, there is no one like You"""),
    song("538", "G", "Grace Flows Down", """
Amazing grace, how sweet the sound
That saved a wretch like me
I once was lost but now I'm found
Was blind but now I see
Chorus:
Grace flows down and covers me
Grace flows down and covers me
Grace flows down and covers me
Grace flows down and covers me
Hallelujah, grace like rain falls down on me
Hallelujah, all my stains are washed away
They're washed away"""),
    song("539", "G", "Healer", """
You hold my every moment
You calm my raging seas
You walk with me through fire
And heal all my disease
I trust in You, I trust in You
Chorus:
I believe You're my Healer
I believe You are all I need
I believe You're my portion
I believe You're more than enough for me
Jesus, You're all I need
Nothing is impossible for You
Nothing is impossible for You
Nothing is impossible for You
You hold my world in Your hands"""),
    song("540", "G", "In Your Presence", """
In Your presence, O God, my soul is satisfied
In Your presence, O God, my soul is satisfied
Chorus:
In Your presence, O God, my soul is satisfied
In Your presence, O God, my soul is satisfied
I will worship You with all of my heart
I will worship You with all of my mind
I will worship You with all of my strength
For You are my God"""),
    song("541", "G", "More Love, More Power", """
More love, more power, more of You in my life
More love, more power, more of You in my life
Chorus:
And I will worship You with all of my heart
And I will worship You with all of my mind
And I will worship You with all of my strength
For You are my Lord
More love, more power, more of You in my life
More love, more power, more of You in my life"""),
    song("542", "G", "Come Now Is the Time to Worship", """
Come, now is the time to worship
Come, now is the time to give your heart
Come, just as you are to worship
Come, just as you are before your God
Come
Chorus:
One day every tongue will confess You are God
One day every knee will bow
Still the greatest treasure remains for those
Who gladly choose You now
Come, now is the time to worship
Come, now is the time to give your heart
Come, just as you are to worship
Come, just as you are before your God
Come"""),
    song("543", "G", "Ever Be", """
Your love is devoted like a ring of solid gold
Like a vow to be faithful, like a covenant of old
Your love is enduring through the winter rain
And beyond the horizon with mercy for today
Chorus:
You will be praised, You will be praised
Your love makes us brave, Your love makes us brave
We will make a way, we will make a way
Your love makes us brave, Your love makes us brave
Faithful You have been and faithful You will be
You pledge Yourself to me and that is why my heart replies
The Lord, my God, my King, my love
Your love, it never fails, it never gives up
It never runs out on me"""),
    song("544", "G", "Center", """
Jesus, be the center, be my source, be my light, Jesus
Jesus, be the center, be my hope, be my song, Jesus
Chorus:
Be the fire in my heart, be the wind in these sails
Be the reason that I live, Jesus, Jesus
Jesus, be my vision, be my way, be my guide, Jesus
Jesus, be my vision, be my way, be my guide, Jesus
Jesus, be the center, be my source, be my light, Jesus"""),
    song("545", "G", "Praise", """
Let everything that has breath praise the Lord
Praise the Lord
Let everything that has breath praise the Lord
Praise the Lord
Chorus:
I'll praise in the valley, praise on the mountain
I'll praise when I'm sured up, praise when I'm doubting
I'll praise when outnumbered, praise when surrounded
'Cause praise is the highway to the throne of God
Praise is the highway to the heart of God
Praise is the highway to the move of God
Revival is in our praises
Let everything that has breath praise the Lord
Praise the Lord"""),
    song("546", "G", "Trust In God", """
When I cannot see You with my eyes
Let my heart believe where my hope lies
I will trust in God, my Savior
The One who will never fail
He will never fail
Chorus:
I trust in God, my Savior
The One who will never fail
He will never fail
I trust in God, my Savior
The One who will never fail
He will never fail
When the ground beneath me starts to shake
And I can't see the way ahead
You have never failed me yet
I will trust in God, my Savior
The One who will never fail"""),
    song("547", "D", "I Believe", """
I believe in the Son, I believe in the Risen One
I believe I overcome by the power of His blood
Chorus:
I believe, I believe it is well with my soul
I believe, I believe it is well with my soul
I believe in the One whose love never ends
I believe in the One who makes all things new
I believe in the One who holds me in His hands
I believe in the One who will never let me go"""),
    song("548", "G", "House of the Lord", """
There's joy in the house of the Lord
There's joy in the house of the Lord today
And we won't be quiet
We shout out Your praise
Chorus:
We sing to the God who heals
We sing to the God who saves
We sing to the God who always makes a way
'Cause He hung up on that cross, then He rose up from that grave
My hope is alive, my hope is alive
There's joy in the house of the Lord
There's joy in the house of the Lord today
And we won't be quiet
We shout out Your praise"""),
    song("549", "G", "See A Victory", """
The weapon may be formed but it won't prosper
And when the darkness falls it won't prevail
'Cause the God I serve knows only how to triumph
My God will never fail
Oh, my God will never fail
Chorus:
I see a victory, I see a victory
Oh, what the Lord can do, I see a victory
I see a victory, I see a victory
Oh, what the Lord can do, I see a victory
The weapon may be formed but it won't prosper
And when the darkness falls it won't prevail
'Cause the God I serve knows only how to triumph
My God will never fail"""),
    song("550", "G", "Waiting Here for You", """
If faith can move the mountains, let the mountains move
We come with expectation, waiting here for You
Waiting here for You
Chorus:
You're the Lord of all creation and still You know my heart
The Author of salvation, You've loved us from the start
Waiting here for You, waiting here for You
With our hands lifted high in praise and our hearts bowed down
We'll run with passion for Your name, we'll sing with all we are
Waiting here for You, waiting here for You
All that I am is Yours, all that I have is Yours
I give You my life, I give You my all
Waiting here for You"""),
]


def main() -> None:
    with open(SONGS_PATH, encoding="utf-8") as handle:
        songs = json.load(handle)

    existing_numbers = {s["number"] for s in songs if s.get("number")}
    existing_titles = {s["title"].lower().strip() for s in songs}

    added = 0
    for entry in NEW_SONGS:
        if entry["number"] in existing_numbers:
            continue
        if entry["title"].lower().strip() in existing_titles:
            continue
        songs.append(entry)
        existing_numbers.add(entry["number"])
        existing_titles.add(entry["title"].lower().strip())
        added += 1

    songs.sort(key=lambda s: int(s["number"]) if s["number"].isdigit() else 999999)

    with open(SONGS_PATH, "w", encoding="utf-8") as handle:
        json.dump(songs, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    print(f"Added {added} songs. Total: {len(songs)}")


if __name__ == "__main__":
    main()
