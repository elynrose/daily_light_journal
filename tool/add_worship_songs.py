"""Fix song 374 corruption and append popular worship songs."""
import json
import os

SONGS_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "samples", "songs_library_template.json")

BLESSED_BE_LYRICS = """Blessed be the name of the Lord
Blessed be the name of the Lord
Blessed be the name of the Lord
Most High
Blessed be the name of the Lord
Blessed be the name of the Lord
Blessed be the name of the Lord
Most High
The name of the Lord is
A strong tower
The righteous run into it
And they are saved
The name of the Lord is
A strong tower
The righteous run into it
And they are saved
Jesus is the name of the Lord
Jesus is the name of the Lord
Jesus is the name of the Lord
Most High
Jesus is the name of the Lord
Jesus is the name of the Lord
Jesus is the name of the Lord
Most High"""

BE_NOT_AFRAID_LYRICS = """Be not afraid, put fear aside
I have sent my Prophet to prepare my Bride.
I am coming soon, for our honeymoon
And to take my loved one with me to the sky
There's a table spread and greetings to be said
And some tears to wipe away from off your eyes.
Do not cry anymore, it is written thus before.
For it's all over now my beloved
The parting's been a time of trial,
Weary moments and distress for just a while.
That I would be true I have said to you
And my promise I have never passed aside.
You have never seen the half of what I mean,
Nor can understand the things prepared for you.
Face to face, will it be, what a rapture and for thee,
For it's all over now, my beloved
There is a joy, a greeting sweet,
Cares and sorrows leave
When loved ones come to meet.
Where the burdens fall, to be not at all.
Heart to heart and eye to eye eternally.
Hear the Bridegroom's call, it's not to one and all
But to her who stays within My every Word.
Part of Me, of my heart, we will gather not to part
For it's all over now, my beloved"""

NEW_SONGS = [
    {
        "number": "376",
        "key": "B",
        "title": "Way Maker",
        "lyrics": """You are here, moving in our midst
I worship You, I worship You
You are here, working in this place
I worship You, I worship You
Chorus:
Way Maker, Miracle Worker, Promise Keeper
Light in the darkness, my God
That is who You are
Way Maker, Miracle Worker, Promise Keeper
Light in the darkness, my God
That is who You are
You are here, touching every heart
I worship You, I worship You
You are here, healing every heart
I worship You, I worship You
You are here, turning lives around
I worship You, I worship You
You are here, mending every heart
I worship You, I worship You
Even when I don't see it, You're working
Even when I don't feel it, You're working
You never stop, You never stop working
You never stop, You never stop working""",
    },
    {
        "number": "377",
        "key": "A",
        "title": "Goodness of God",
        "lyrics": """I love You, Lord, for Your mercy never fails me
All my days I've been held in Your hand
From the moment that I wake up until I lay my head
Oh, I will sing of the goodness of God
Chorus:
'Cause all my life You have been faithful
All my life You have been so, so good
With every breath that I am able
Oh, I will sing of the goodness of God
I love Your voice, You have led me through the fire
In darkest nights You are close like no other
I've known You as a Father, I've known You as a Friend
And I have lived in the goodness of God""",
    },
    {
        "number": "378",
        "key": "D",
        "title": "What a Beautiful Name",
        "lyrics": """You were the Word at the beginning
One with God the Lord Most High
Your hidden glory in creation
Now revealed in You our Christ
Chorus:
What a beautiful Name it is
What a beautiful Name it is
The Name of Jesus Christ my King
What a beautiful Name it is
Nothing compares to this
What a beautiful Name it is
The Name of Jesus
You didn't want heaven without us
So Jesus You brought heaven down
My sin was great, Your love was greater
What could separate us now
Death could not hold You, the veil tore before You
You silenced the boast of sin and grave
The heavens are roaring the praise of Your glory
For You are raised to life again""",
    },
    {
        "number": "379",
        "key": "G",
        "title": "Shout to the Lord",
        "lyrics": """My Jesus, my Saviour
Lord, there is none like You
All of my days I want to praise
The wonders of Your mighty love
My comfort, my shelter
Tower of refuge and strength
Let every breath, all that I am
Never cease to worship You
Chorus:
Shout to the Lord, all the earth let us sing
Power and majesty, praise to the King
Mountains bow down and the seas will roar
At the sound of Your name
I sing for joy at the work of Your hands
Forever I'll love You, forever I'll stand
Nothing compares to the promise I have in You""",
    },
    {
        "number": "380",
        "key": "D",
        "title": "Here I Am to Worship",
        "lyrics": """Light of the world, You stepped down into darkness
Opened my eyes, let me see
Beauty that made this heart adore You
Hope of a life spent with You
Chorus:
Here I am to worship
Here I am to bow down
Here I am to say that You're my God
You're altogether lovely
Altogether worthy
Altogether wonderful to me
King of all days, oh so highly exalted
Glorious in heaven above
Peoples bow down and worship before You
Lord, I love to bring You all that I am""",
    },
    {
        "number": "381",
        "key": "A",
        "title": "Mighty to Save",
        "lyrics": """Everyone needs compassion
Love that's never failing
Let mercy fall on me
Everyone needs forgiveness
The kindness of a Saviour
The hope of nations
Chorus:
Saviour, He can move the mountains
My God is mighty to save
He is mighty to save
Forever, Author of salvation
He rose and conquered the grave
Jesus conquered the grave
So take me as You find me
All my fears and failures
Fill my life again
God, I give You my destiny
I'm giving You all that I am
To be used for Your glory""",
    },
    {
        "number": "382",
        "key": "D",
        "title": "In Christ Alone",
        "lyrics": """In Christ alone my hope is found
He is my light, my strength, my song
This Cornerstone, this solid Ground
Firm through the fiercest drought and storm
What heights of love, what depths of peace
When fears are stilled, when strivings cease
My Comforter, my All in All
Here in the love of Christ I stand
In Christ alone, who took on flesh
Fullness of God in helpless babe
This gift of love and righteousness
Scorned by the ones He came to save
Till on that cross as Jesus died
The wrath of God was satisfied
For every sin on Him was laid
Here in the death of Christ I live""",
    },
    {
        "number": "383",
        "key": "D",
        "title": "Great Is Thy Faithfulness",
        "lyrics": """Great is Thy faithfulness, O God my Father
There is no shadow of turning with Thee
Thou changest not, Thy compassions they fail not
As Thou hast been Thou forever wilt be
Chorus:
Great is Thy faithfulness
Great is Thy faithfulness
Morning by morning new mercies I see
All I have needed Thy hand hath provided
Great is Thy faithfulness, Lord, unto me
Summer and winter and springtime and harvest
Sun, moon and stars in their courses above
Join with all nature in manifold witness
To Thy great faithfulness, mercy and love
Pardon for sin and a peace that endureth
Thine own dear presence to cheer and to guide
Strength for today and bright hope for tomorrow
Blessings all mine, with ten thousand beside""",
    },
    {
        "number": "384",
        "key": "D",
        "title": "Blessed Assurance",
        "lyrics": """Blessed assurance, Jesus is mine
Oh, what a foretaste of glory divine
Heir of salvation, purchase of God
Born of His Spirit, washed in His blood
Chorus:
This is my story, this is my song
Praising my Saviour all the day long
This is my story, this is my song
Praising my Saviour all the day long
Perfect submission, perfect delight
Visions of rapture now burst on my sight
Angels descending bring from above
Echoes of mercy, whispers of love
Perfect submission, all is at rest
I in my Saviour am happy and blest
Watching and waiting, looking above
Filled with His goodness, lost in His love""",
    },
    {
        "number": "385",
        "key": "G",
        "title": "I'll Fly Away",
        "lyrics": """Some glad morning when this life is o'er
I'll fly away
To a home on God's celestial shore
I'll fly away
Chorus:
I'll fly away, oh glory
I'll fly away in the morning
When I die, hallelujah by and by
I'll fly away
Just a few more weary days and then
I'll fly away
To a land where joy shall never end
I'll fly away""",
    },
    {
        "number": "386",
        "key": "G",
        "title": "Rock of Ages",
        "lyrics": """Rock of Ages, cleft for me
Let me hide myself in Thee
Let the water and the blood
From Thy wounded side which flowed
Be of sin the double cure
Save from wrath and make me pure
Could my tears forever flow
Could my zeal no lullaby know
These for sin could not atone
Thou must save, and Thou alone
In my hand no price I bring
Simply to Thy cross I cling
While I draw this fleeting breath
When my eyes shall close in death
When I rise to worlds unknown
And behold Thee on Thy throne
Rock of Ages, cleft for me
Let me hide myself in Thee""",
    },
    {
        "number": "387",
        "key": "D",
        "title": "Come Thou Fount",
        "lyrics": """Come Thou Fount of every blessing
Tune my heart to sing Thy grace
Streams of mercy, never ceasing
Call for songs of loudest praise
Teach me some melodious sonnet
Sung by flaming tongues above
Praise the mount, I'm fixed upon it
Mount of Thy redeeming love
Here I raise my Ebenezer
Hither by Thy help I'm come
And I hope by Thy good pleasure
Safely to arrive at home
Jesus sought me when a stranger
Wandering from the fold of God
He to rescue me from danger
Interposed His precious blood
Oh, to grace how great a debtor
Daily I'm constrained to be
Let Thy goodness like a fetter
Bind my wandering heart to Thee
Prone to wander, Lord, I feel it
Prone to leave the God I love
Here's my heart, oh take and seal it
Seal it for Thy courts above""",
    },
    {
        "number": "388",
        "key": "E",
        "title": "Be Thou My Vision",
        "lyrics": """Be Thou my Vision, O Lord of my heart
Naught be all else to me, save that Thou art
Thou my best Thought, by day or by night
Waking or sleeping, Thy presence my light
Be Thou my Wisdom, and Thou my true Word
I ever with Thee and Thou with me, Lord
Thou my great Father, I Thy true son
Thou in me dwelling, and I with Thee one
Riches I heed not, nor man's empty praise
Thou mine Inheritance, now and always
Thou and Thou only, first in my heart
High King of heaven, my Treasure Thou art
High King of heaven, my victory won
May I reach heaven's joys, O bright heaven's Sun
Heart of my own heart, whatever befall
Still be my Vision, O Ruler of all""",
    },
    {
        "number": "389",
        "key": "D",
        "title": "Holy, Holy, Holy",
        "lyrics": """Holy, holy, holy! Lord God Almighty
Early in the morning our song shall rise to Thee
Holy, holy, holy, merciful and mighty
God in three Persons, blessed Trinity
Holy, holy, holy! All the saints adore Thee
Casting down their golden crowns around the glassy sea
Cherubim and seraphim falling down before Thee
Which wert, and art, and evermore shalt be
Holy, holy, holy! Though the darkness hide Thee
Though the eye of sinful man Thy glory may not see
Only Thou art holy, there is none beside Thee
Perfect in power, in love, and purity""",
    },
    {
        "number": "390",
        "key": "D",
        "title": "Open the Eyes of My Heart",
        "lyrics": """Open the eyes of my heart, Lord
Open the eyes of my heart
I want to see You
I want to see You
To see You high and lifted up
Shining in the light of Your glory
Pour out Your power and love
As we sing holy, holy, holy
Holy, holy, holy
Holy, holy, holy
I want to see You""",
    },
    {
        "number": "391",
        "key": "C",
        "title": "Revelation Song",
        "lyrics": """Worthy is the Lamb who was slain
Holy, holy is He
Sing a new song to Him who sits on
Heaven's mercy seat
Chorus:
Holy, holy, holy is the Lord God Almighty
Who was and is and is to come
With all creation I sing praise to the King of kings
You are my everything, and I will adore You
Clothed in rainbows of living color
Flashes of lightning, rolls of thunder
Blessing and honor, strength and glory
And power be to You the only wise King
Filled with wonder, awestruck wonder
At the mention of Your name
Jesus Your name is power, breath and living water
Such a marvelous mystery""",
    },
    {
        "number": "392",
        "key": "G",
        "title": "Build My Life",
        "lyrics": """Worthy of every song we could ever sing
Worthy of all the praise we could ever bring
Worthy of every breath we could ever breathe
We live for You
Jesus, the Name above every other name
Jesus, the only One who could ever save
Worthy of every breath we could ever breathe
We live for You
Chorus:
Holy, there is no one like You
There is none beside You
Open up my eyes in wonder
Show me who You are and fill me
With Your heart and lead me
In Your love to those around me
And I will build my life upon Your love
It is a firm foundation
And I will put my trust in You alone
And I will not be shaken""",
    },
    {
        "number": "393",
        "key": "G",
        "title": "Living Hope",
        "lyrics": """How great the chasm that lay between us
How high the mountain I could not climb
In desperation I turned to heaven
And spoke Your name into the night
Then through the darkness Your loving kindness
Tore through the shadows of my soul
The work is finished, the end is written
Jesus Christ, my living hope
Chorus:
Hallelujah, praise the One who set me free
Hallelujah, death has lost its grip on me
You have broken every chain
There's salvation in Your name
Jesus Christ, my living hope
Who could imagine so great a mercy
What heart could fathom such boundless grace
The God of ages stepped down from glory
To wear my sin and bear my shame""",
    },
    {
        "number": "394",
        "key": "G",
        "title": "10,000 Reasons (Bless the Lord)",
        "lyrics": """Bless the Lord, O my soul
O my soul
Worship His holy name
Sing like never before
O my soul
I'll worship Your holy name
The sun comes up, it's a new day dawning
It's time to sing Your song again
Whatever may pass and whatever lies before me
Let me be singing when the evening comes
You're rich in love and You're slow to anger
Your name is great and Your heart is kind
For all Your goodness I will keep on singing
Ten thousand reasons for my heart to find
And on that day when my strength is failing
The end draws near and my time has come
Still my soul will sing Your praise unending
Ten thousand years and then forevermore""",
    },
    {
        "number": "395",
        "key": "A",
        "title": "Good Good Father",
        "lyrics": """I've heard a thousand stories of what they think You're like
But I've heard the tender whisper of love in the dead of night
And You tell me that You're pleased and that I'm never alone
Chorus:
You're a good, good Father
It's who You are, it's who You are, it's who You are
And I'm loved by You
It's who I am, it's who I am, it's who I am
Oh, and I've seen many searching for answers far and wide
But I know we're all searching for answers only You provide
'Cause You know just what we need before we say a word
You are perfect in all of Your ways
You are perfect in all of Your ways
You are perfect in all of Your ways to us
Love so undeniable I can hardly speak
Peace so unexplainable I can hardly think
As You call me deeper still
As You call me deeper still
As You call me deeper still into love, love, love""",
    },
    {
        "number": "396",
        "key": "G",
        "title": "The Old Rugged Cross",
        "lyrics": """On a hill far away stood an old rugged cross
The emblem of suffering and shame
And I love that old cross where the dearest and best
For a world of lost sinners was slain
Chorus:
So I'll cherish the old rugged cross
Till my trophies at last I lay down
I will cling to the old rugged cross
And exchange it some day for a crown
Oh, that old rugged cross, so despised by the world
Has a wondrous attraction for me
For the dear Lamb of God left His glory above
And bore it to dark Calvary
In the old rugged cross, stained with blood so divine
A wondrous beauty I see
For 'twas on that old cross Jesus suffered and died
To pardon and sanctify me""",
    },
    {
        "number": "397",
        "key": "G",
        "title": "Nothing But the Blood",
        "lyrics": """What can wash away my sin?
Nothing but the blood of Jesus
What can make me whole again?
Nothing but the blood of Jesus
Chorus:
Oh, precious is the flow
That makes me white as snow
No other fount I know
Nothing but the blood of Jesus
For my pardon this I see
Nothing but the blood of Jesus
For my cleansing this my plea
Nothing but the blood of Jesus
Nothing can for sin atone
Nothing but the blood of Jesus
Naught of good that I have done
Nothing but the blood of Jesus""",
    },
    {
        "number": "398",
        "key": "F",
        "title": "Just As I Am",
        "lyrics": """Just as I am, without one plea
But that Thy blood was shed for me
And that Thou bidd'st me come to Thee
O Lamb of God, I come, I come
Just as I am, and waiting not
To rid my soul of one dark blot
To Thee whose blood can cleanse each spot
O Lamb of God, I come, I come
Just as I am, though tossed about
With many a conflict, many a doubt
Fightings and fears within, without
O Lamb of God, I come, I come
Just as I am, poor, wretched, blind
Sight, riches, healing of the mind
Yea, all I need in Thee to find
O Lamb of God, I come, I come
Just as I am, Thou wilt receive
Wilt welcome, pardon, cleanse, relieve
Because Thy promise I believe
O Lamb of God, I come, I come""",
    },
    {
        "number": "399",
        "key": "G",
        "title": "Who You Say I Am",
        "lyrics": """Who am I that the highest King
Would welcome me
I was lost but He brought me in
Oh His love for me
Oh His love for me
Chorus:
Who the Son sets free
Oh is free indeed
I'm a child of God
Yes I am
In my Father's house there's a place for me
I'm a child of God
Yes I am
Free at last, He has ransomed me
His grace runs deep
While I was a slave to sin
Jesus died for me
Yes He died for me
I am chosen, not forsaken
I am who You say I am
You are for me, not against me
I am who You say I am""",
    },
    {
        "number": "400",
        "key": "G",
        "title": "King of Kings",
        "lyrics": """In the darkness we were waiting
Without hope without light
Till from heaven You came running
There was mercy in Your eyes
To fulfil the law and prophets
To a virgin came the Word
From a throne of endless glory
To a cradle in the dirt
Chorus:
Praise the Father, praise the Son
Praise the Spirit three in one
God of glory, Majesty
Praise forever to the King of Kings
To reveal the kingdom coming
And to reconcile the lost
To redeem the whole creation
You did not despise the cross
For even in Your suffering
You saw to the other side
Knowing this was our salvation
Jesus for our sake You died""",
    },
]


def main() -> None:
    with open(SONGS_PATH, encoding="utf-8") as handle:
        songs = json.load(handle)

    for song in songs:
        if song["number"] == "374":
            song["lyrics"] = BLESSED_BE_LYRICS
            break

    songs.append(
        {
            "number": "375",
            "key": "F",
            "title": "Be not afraid, put fear aside",
            "lyrics": BE_NOT_AFRAID_LYRICS,
        }
    )
    songs.extend(NEW_SONGS)

    with open(SONGS_PATH, "w", encoding="utf-8") as handle:
        json.dump(songs, handle, indent=2, ensure_ascii=False)
        handle.write("\n")

    print(f"Updated songs.json: {len(songs)} total songs")


if __name__ == "__main__":
    main()
