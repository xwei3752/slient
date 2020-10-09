module Sources.Services.AmazonS3 exposing (defaults, initialData, makeTrackUrl, makeTree, parseErrorResponse, parsePreparationResponse, parseTreeResponse, postProcessTree, prepare, properties)

{-| Amazon S3 Service.

Resources:

  - <http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html>

-}

import Common
import Dict
import Http
import Sources exposing (Property, SourceData)
import Sources.Pick
import Sources.Processing exposing (..)
import Sources.Services.AmazonS3.Parser as Parser
import Sources.Services.AmazonS3.Presign exposing (..)
import Sources.Services.Common exposing (cleanPath, noPrep)
import Time



-- PROPERTIES
-- 📟


defaults =
    { bucketName = "music"
    , name = "Music from Amazon S3"
    , region = "eu-west-1"
    }


{-| The list of properties we need from the user.
-}
properties : List Property
properties =
    [ { key = "accessKey"
      , label = "Access key"
      , placeholder = "Fv6EWfLfCcMo"
      , password = True
      }
    , { key = "secretKey"
      , label = "Secret key"
      , placeholder = "qeNcqiMpgqC8"
      , password = True
      }
    , { key = "bucketName"
      , label = "Bucket name"
      , placeholder = "music"
      , password = False
      }
    , { key = "region"
      , label = "Region"
      , placeholder = defaults.region
      , password = False
      }
    , { key = "directoryPath"
      , label = "Directory (Optional)"
      , placeholder = "/"
      , password = False
      }
    , { key = "host"
      , label = "Host (Optional)"
      , placeholder = "http://localhost:9000"
      , password = False
      }
    ]


{-| Initial data set.
-}
initialData : SourceData
initialData =
    Dict.fromList
        [ ( "accessKey", "" )
        , ( "bucketName", defaults.bucketName )
        , ( "directoryPath", "" )
        , ( "host", "" )
        , ( "name", defaults.name )
        , ( "region", defaults.region )
        , ( "secretKey", "" )
        ]



-- PREPARATION


prepare : String -> SourceData -> Marker -> (Result Http.Error String -> msg) -> Maybe (Cmd msg)
prepare _ _ _ _ =
    Nothing



-- TREE


{-| Create a directory tree.

List all the tracks in the bucket.
Or a specific directory in the bucket.

-}
makeTree : SourceData -> Marker -> Time.Posix -> (Result Http.Error String -> msg) -> Cmd msg
makeTree srcData marker currentTime resultMsg =
    let
        directoryPath =
            srcData
                |> Dict.get "directoryPath"
                |> Maybe.withDefault ""
                |> cleanPath

        initialParams =
            [ ( "list-type", "2" )
            , ( "max-keys", "750" )
            ]

        prefix =
            if String.length directoryPath > 0 then
                [ ( "prefix", directoryPath ) ]

            else
                []

        continuation =
            case marker of
                InProgress s ->
                    [ ( "continuation-token", s ) ]

                _ ->
                    []

        params =
            initialParams ++ prefix ++ continuation

        url =
            presignedUrl Get (60 * 5) params currentTime srcData "/"
    in
    Http.get
        { url = url
        , expect = Http.expectStringResponse resultMsg Common.translateHttpResponse
        }


{-| Re-export parser functions.
-}
parsePreparationResponse : String -> SourceData -> Marker -> PrepationAnswer Marker
parsePreparationResponse =
    noPrep


parseTreeResponse : String -> Marker -> TreeAnswer Marker
parseTreeResponse =
    Parser.parseTreeResponse


parseErrorResponse : String -> Maybe String
parseErrorResponse =
    Parser.parseErrorResponse



-- POST


{-| Post process the tree results.

Make sure we only use music files that we can use.

-}
postProcessTree : List String -> List String
postProcessTree =
    Sources.Pick.selectMusicFiles



-- TRACK URL


{-| Create a public url for a file.

We need this to play the track.
Creates a presigned url that's valid for 48 hours

-}
makeTrackUrl : Time.Posix -> SourceData -> HttpMethod -> String -> String
makeTrackUrl currentTime srcData method pathToFile =
    presignedUrl method 172800 [] currentTime srcData pathToFile
