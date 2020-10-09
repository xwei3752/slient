module UI.Tracks.View exposing (view)

import Chunky exposing (..)
import Color exposing (Color)
import Color.Ext as Color
import Common exposing (Switch(..))
import Conditional exposing (ifThenElse)
import Coordinates exposing (Viewport)
import Css.Classes as C
import Html exposing (Html, text)
import Html.Attributes exposing (href, placeholder, style, tabindex, target, title, value)
import Html.Events exposing (onBlur, onClick, onInput)
import Html.Events.Extra.Mouse as Mouse
import Html.Ext exposing (onEnterKey)
import Html.Lazy exposing (..)
import List.Ext as List
import List.Extra as List
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Maybe.Extra as Maybe
import Playlists exposing (Playlist)
import Sources
import Tracks exposing (..)
import Tracks.Collection exposing (..)
import UI.Kit
import UI.Navigation exposing (..)
import UI.Page
import UI.Playlists.Page
import UI.Queue.Page
import UI.Sources.Page as Sources
import UI.Tracks.Scene.List
import UI.Tracks.Types exposing (..)
import UI.Types as UI exposing (..)



-- 🗺


type alias Dependencies =
    { amountOfSources : Int
    , bgColor : Maybe Color
    , darkMode : Bool
    , isOnIndexPage : Bool
    , isTouchDevice : Bool
    , sourceIdsBeingProcessed : List String
    , viewport : Viewport
    }


view : Model -> Dependencies -> Html UI.Msg
view model deps =
    chunk
        viewClasses
        [ lazy6
            navigation
            model.grouping
            model.favouritesOnly
            model.searchTerm
            model.selectedPlaylist
            deps.isOnIndexPage
            deps.bgColor

        --
        , if List.isEmpty model.tracks.harvested then
            lazy4
                noTracksView
                deps.sourceIdsBeingProcessed
                deps.amountOfSources
                (List.length model.tracks.harvested)
                (List.length model.favourites)

          else
            case model.scene of
                List ->
                    listView model deps
        ]


viewClasses : List String
viewClasses =
    [ C.flex
    , C.flex_col
    , C.flex_grow
    ]


navigation : Maybe Grouping -> Bool -> Maybe String -> Maybe Playlist -> Bool -> Maybe Color -> Html UI.Msg
navigation maybeGrouping favouritesOnly searchTerm selectedPlaylist isOnIndexPage bgColor =
    let
        tabindex_ =
            ifThenElse isOnIndexPage 0 -1
    in
    chunk
        [ C.flex ]
        [ -----------------------------------------
          -- Part 1
          -----------------------------------------
          chunk
            [ C.border_b
            , C.border_r
            , C.border_gray_300
            , C.flex
            , C.flex_grow
            , C.mt_px
            , C.overflow_hidden
            , C.relative
            , C.text_gray_600

            -- Dark mode
            ------------
            , C.dark__border_base01
            , C.dark__text_base04
            ]
            [ -- Input
              --------
              slab
                Html.input
                [ onBlur (TracksMsg Search)
                , onEnterKey (TracksMsg Search)
                , onInput (TracksMsg << SetSearchTerm)
                , placeholder "Search"
                , tabindex tabindex_
                , value (Maybe.withDefault "" searchTerm)
                ]
                [ C.bg_transparent
                , C.border_none
                , C.flex_grow
                , C.h_full
                , C.ml_1
                , C.mt_px
                , C.outline_none
                , C.pl_8
                , C.pr_2
                , C.pt_px
                , C.text_base02
                , C.text_sm
                , C.w_full

                -- Dark mode
                ------------
                , C.dark__text_base06
                ]
                []

            -- Search icon
            --------------
            , chunk
                [ C.absolute
                , C.bottom_0
                , C.flex
                , C.items_center
                , C.left_0
                , C.ml_3
                , C.mt_px
                , C.top_0
                , C.z_0
                ]
                [ Icons.search 16 Inherit ]

            -- Actions
            ----------
            , chunk
                [ C.flex
                , C.items_center
                , C.mr_3
                , C.mt_px
                , C.pt_px
                ]
                [ -- 1
                  case searchTerm of
                    Just _ ->
                        brick
                            [ onClick (TracksMsg ClearSearch)
                            , title "Clear search"
                            ]
                            [ C.cursor_pointer
                            , C.ml_1
                            , C.mt_px
                            ]
                            [ Icons.clear 16 Inherit ]

                    Nothing ->
                        nothing

                -- 2
                , brick
                    [ onClick (TracksMsg ToggleFavouritesOnly)
                    , title "Toggle favourites-only"
                    ]
                    [ C.cursor_pointer
                    , C.ml_1
                    ]
                    [ case favouritesOnly of
                        True ->
                            Icons.favorite 16 (Color UI.Kit.colorKit.base08)

                        False ->
                            Icons.favorite_border 16 Inherit
                    ]

                -- 3
                , brick
                    [ Mouse.onClick (TracksMsg << ShowViewMenu maybeGrouping)
                    , title "View settings"
                    ]
                    [ C.cursor_pointer
                    , C.ml_1
                    ]
                    [ Icons.more_vert 16 Inherit ]

                -- 4
                , case selectedPlaylist of
                    Just playlist ->
                        brick
                            [ onClick DeselectPlaylist

                            --
                            , bgColor
                                |> Maybe.withDefault UI.Kit.colorKit.base01
                                |> Color.toCssString
                                |> style "background-color"
                            ]
                            [ C.antialiased
                            , C.cursor_pointer
                            , C.duration_500
                            , C.font_bold
                            , C.leading_none
                            , C.ml_1
                            , C.px_1
                            , C.py_1
                            , C.rounded
                            , C.truncate
                            , C.text_white_90
                            , C.text_xxs
                            , C.transition

                            -- Dark mode
                            ------------
                            , C.dark__text_white_60
                            ]
                            [ chunk
                                [ C.px_px, C.pt_px ]
                                [ text playlist.name ]
                            ]

                    Nothing ->
                        nothing
                ]
            ]
        , -----------------------------------------
          -- Part 2
          -----------------------------------------
          UI.Navigation.localWithTabindex
            tabindex_
            [ ( Icon Icons.waves
              , Label "Playlists" Hidden
              , NavigateToPage (UI.Page.Playlists UI.Playlists.Page.Index)
              )
            , ( Icon Icons.schedule
              , Label "Queue" Hidden
              , NavigateToPage (UI.Page.Queue UI.Queue.Page.Index)
              )
            , ( Icon Icons.equalizer
              , Label "Equalizer" Hidden
              , NavigateToPage UI.Page.Equalizer
              )
            ]
        ]


noTracksView : List String -> Int -> Int -> Int -> Html UI.Msg
noTracksView processingContext amountOfSources amountOfTracks amountOfFavourites =
    chunk
        [ C.flex, C.flex_grow ]
        [ UI.Kit.centeredContent
            [ if List.length processingContext > 0 then
                message "Processing Tracks"

              else if amountOfSources == 0 then
                chunk
                    [ C.flex
                    , C.flex_wrap
                    , C.items_start
                    , C.justify_center
                    , C.px_3
                    ]
                    [ -- Add
                      ------
                      inline
                        [ C.mb_3, C.mx_2, C.whitespace_no_wrap ]
                        [ UI.Kit.buttonLink
                            (Sources.NewOnboarding
                                |> UI.Page.Sources
                                |> UI.Page.toString
                            )
                            UI.Kit.Filled
                            (buttonContents
                                [ UI.Kit.inlineIcon Icons.add
                                , text "Add some music"
                                ]
                            )
                        ]

                    -- Demo
                    -------
                    , inline
                        [ C.mb_3, C.mx_2, C.whitespace_no_wrap ]
                        [ UI.Kit.buttonWithColor
                            UI.Kit.Gray
                            UI.Kit.Normal
                            InsertDemo
                            (buttonContents
                                [ UI.Kit.inlineIcon Icons.music_note
                                , text "Insert demo"
                                ]
                            )
                        ]

                    -- How
                    ------
                    ]

              else if amountOfTracks == 0 then
                message "No tracks found"

              else
                message "No sources available"
            ]
        ]


buttonContents : List (Html UI.Msg) -> Html UI.Msg
buttonContents =
    inline
        [ C.flex
        , C.items_center
        , C.leading_0
        ]


message : String -> Html UI.Msg
message m =
    chunk
        [ C.border_b_2
        , C.border_current_color
        , C.text_sm
        , C.font_semibold
        , C.leading_snug
        , C.pb_1
        ]
        [ text m ]


listView : Model -> Dependencies -> Html UI.Msg
listView model deps =
    model.selectedPlaylist
        |> Maybe.map .autoGenerated
        |> Maybe.andThen
            (\bool ->
                if bool then
                    Nothing

                else
                    Just model.dnd
            )
        |> UI.Tracks.Scene.List.view
            { bgColor = deps.bgColor
            , darkMode = deps.darkMode
            , height = deps.viewport.height
            , isTouchDevice = deps.isTouchDevice
            , isVisible = deps.isOnIndexPage
            , showAlbum = deps.viewport.width >= 720
            }
            model.tracks.harvested
            model.infiniteList
            model.favouritesOnly
            model.nowPlaying
            model.searchTerm
            model.sortBy
            model.sortDirection
            model.selectedTrackIndexes
