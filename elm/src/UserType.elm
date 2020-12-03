module UserType exposing
    ( User
    )

type alias User =
    { name : String
    , repoUrl : String
    , languages : String
    }