module UserType exposing (PushInfo, User)


type alias User =
    { name : String
    , repoUrl : String
    , languages : String
    , year : String
    , lastPushed : Maybe PushInfo
    }


type alias PushInfo =
    { lastPushedTime : String
    , lastPushedMessage : String
    }
