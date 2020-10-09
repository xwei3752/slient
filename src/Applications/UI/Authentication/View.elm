module UI.Authentication.View exposing (view)

import Chunky exposing (..)
import Color
import Color.Ext as Color
import Common exposing (Switch(..))
import Conditional exposing (..)
import Css.Classes as C
import Html exposing (Html, a, button, text)
import Html.Attributes exposing (attribute, href, placeholder, src, style, target, title, value, width)
import Html.Events exposing (onClick, onSubmit)
import Html.Events.Extra exposing (onClickStopPropagation)
import Html.Events.Extra.Mouse as Mouse
import Html.Lazy as Lazy
import Markdown
import Material.Icons as Icons
import Material.Icons.Types exposing (Coloring(..))
import Maybe.Extra as Maybe
import String.Ext as String
import Svg exposing (Svg)
import UI.Authentication.Types as Authentication exposing (..)
import UI.Kit
import UI.Svg.Elements
import UI.Types as UI exposing (..)
import User.Layer exposing (..)



-- 🗺


view : Model -> Html UI.Msg
view =
    Html.map AuthenticationMsg << Lazy.lazy view_ << .authentication


view_ : State -> Html Authentication.Msg
view_ state =
    chunk
        [ C.flex
        , C.flex_col
        , C.h_full
        , C.items_center
        ]
        [ brick
            [ style "height" "42%" ]
            [ C.flex
            , C.items_center
            , C.pb_8

            --
            , C.md__pb_0
            ]
            [ -- Logo
              -------
              chunk
                [ C.py_5, C.relative ]
                [ slab
                    Html.img
                    [ onClick CancelFlow
                    , src "images/slient.png"
                    , width 130

                    --
                    , case state of
                        Welcome ->
                            title "Slient"

                        _ ->
                            title "Go back"
                    ]
                    [ case state of
                        Welcome ->
                            C.cursor_default

                        _ ->
                            C.cursor_pointer
                    ]
                    []

                -- Speech bubble
                ----------------
                , case state of
                    InputScreen _ { question } ->
                        question
                            |> String.lines
                            |> List.map String.trimLeft
                            |> String.join "\n"
                            |> Markdown.toHtmlWith
                                { githubFlavored = Nothing
                                , defaultHighlighting = Nothing
                                , sanitize = False
                                , smartypants = True
                                }
                                []
                            |> speechBubble

                    NewEncryptionKeyScreen _ _ ->
                        [ text "This'll prevent other people from reading your data."
                        ]
                            |> chunk []
                            |> speechBubble

                    UpdateEncryptionKeyScreen _ _ ->
                        [ text "This'll prevent other people from reading your data."
                        ]
                            |> chunk []
                            |> speechBubble

                    Welcome ->
                        [ text "Start playing music"
                        ]
                            |> chunk []
                            |> speechBubble

                    _ ->
                        [ text "Where would you like to keep your personal data?"
                        ]
                            |> chunk []
                            |> speechBubble
                ]
            ]

        -----------------------------------------
        -- Content
        -----------------------------------------
        , case state of
            InputScreen method opts ->
                inputScreen opts

            NewEncryptionKeyScreen method pass ->
                encryptionKeyScreen
                    { withEncryption = SignInWithPassphrase method (Maybe.withDefault "" pass)
                    , withoutEncryption = SignIn method
                    }

            UpdateEncryptionKeyScreen method pass ->
                encryptionKeyScreen
                    { withEncryption = UpdateEncryptionKey method (Maybe.withDefault "" pass)
                    , withoutEncryption = RemoveEncryptionKey method
                    }

            Unauthenticated ->
                choicesScreen

            Authenticated _ ->
                choicesScreen

            Welcome ->
                welcomeScreen

        -----------------------------------------
        -- Link to about page
        -----------------------------------------
        ]



-- WELCOME


welcomeScreen : Html Authentication.Msg
welcomeScreen =
    chunk
        [ C.mt_3
        , C.relative
        , C.z_10
        ]
        [ UI.Kit.buttonWithColor
            UI.Kit.Blank
            UI.Kit.Filled
            GetStarted
            (slab
                Html.span
                [ style "font-size" "13px"
                , style "letter-spacing" "0.25em"
                ]
                [ C.align_middle
                , C.inline_block
                , C.pt_px
                ]
                [ text "SIGN IN" ]
            )
        ]



-- CHOICES


choicesScreen : Html Authentication.Msg
choicesScreen =
    chunk
        [ C.bg_white
        , C.rounded
        , C.px_4
        , C.py_2
        , C.relative
        , C.z_10

        -- Dark mode
        ------------
        , C.dark__bg_darkest_hour
        ]
        [ choiceButton
            { action = ShowNewEncryptionKeyScreen Local
            , icon = Icons.web
            , infoLink = Nothing
            , label = "Local"
            , outOfOrder = False
            }
        , choiceButton
            { action =
                AskForInput
                    (Ipfs { apiOrigin = ""})
                    { placeholder = "//localhost:5001"
                        , question = """
                         Where's your IPFS API located?
                         """
                        , value = "//localhost:5001"
                    }
            , icon = \_ _ -> Svg.map never UI.Svg.Elements.ipfsLogo
            , infoLink = Nothing
            , label = "IPFSStorage"
            , outOfOrder = False
            }

        -- More options
        ---------------
        ]


choiceButton :
    { action : msg
    , icon : Int -> Coloring -> Svg msg
    , infoLink : Maybe String
    , label : String
    , outOfOrder : Bool
    }
    -> Html msg
choiceButton { action, icon, infoLink, label, outOfOrder } =
    chunk
        [ C.border_b
        , C.border_gray_300
        , C.relative

        --
        , C.last__border_b_0

        -- Dark mode
        ------------
        , C.dark__border_base01
        ]
        [ -----------------------------------------
          -- Button
          -----------------------------------------
          slab
            button
            [ onClick action ]
            [ C.bg_transparent
            , C.cursor_pointer
            , C.flex
            , C.items_center
            , C.leading_none
            , C.min_w_tiny
            , C.outline_none
            , C.px_2
            , C.py_4
            , C.text_left
            , C.text_sm
            ]
            [ chunk
                [ C.flex
                , C.items_center

                --
                , ifThenElse outOfOrder C.opacity_20 C.opacity_100
                ]
                [ inline
                    [ C.inline_flex, C.mr_4 ]
                    [ icon 16 Inherit ]
                , text label
                ]
            ]

        -----------------------------------------
        -- Info icon
        -----------------------------------------
        , case infoLink of
            Just link ->
                slab
                    Html.a
                    [ style "left" "100%"
                    , style "top" "50%"
                    , style "transform" "translateY(-50%)"

                    --
                    , href link
                    , target "_blank"
                    , title ("Learn more about " ++ label)
                    ]
                    [ C.absolute
                    , C.cursor_pointer
                    , C.duration_100
                    , C.leading_none
                    , C.ml_4
                    , C.minus_translate_y_half
                    , C.opacity_40
                    , C.pl_4
                    , C.text_white
                    , C.transition
                    , C.transform

                    --
                    , C.hocus__opacity_100
                    ]
                    [ Icons.help 17 Inherit ]

            Nothing ->
                nothing
        ]



-- ENCRYPTION KEY


encryptionKeyScreen : { withEncryption : Authentication.Msg, withoutEncryption : Authentication.Msg } -> Html Authentication.Msg
encryptionKeyScreen { withEncryption, withoutEncryption } =
    slab
        Html.form
        [ onSubmit withEncryption ]
        [ C.flex
        , C.flex_col
        , C.max_w_xs
        , C.px_3
        , C.w_screen

        --
        , C.sm__px_0
        ]
        [ UI.Kit.textArea
            [ attribute "autocapitalize" "none"
            , attribute "autocomplete" "off"
            , attribute "autocorrect" "off"
            , attribute "rows" "4"
            , attribute "spellcheck" "false"

            --
            , placeholder "anQLS9Usw24gxUi11IgVBg76z8SCWZgLKkoWIeJ1ClVmBHLRlaiA0CtvONVAMGritbgd3U45cPTxrhFU0WXaOAa8pVt186KyEccfUNyAq97"

            --
            , Html.Events.onInput KeepPassphraseInMemory
            ]
        , UI.Kit.button
            UI.Kit.Filled
            Authentication.Bypass
            (text "Continue")
        , brick
            [ onClickStopPropagation withoutEncryption ]
            [ C.cursor_pointer
            , C.flex
            , C.items_center
            , C.justify_center
            , C.leading_snug
            , C.mt_3
            , C.opacity_50
            , C.text_white
            , C.text_xs
            ]
            [ inline [ C.inline_block, C.leading_none, C.mr_2 ] [ Icons.warning 13 Inherit ]
            , text "Continue without encryption"
            ]
        ]



-- INPUT SCREEN


inputScreen : Question -> Html Authentication.Msg
inputScreen question =
    slab
        Html.form
        [ onSubmit ConfirmInput ]
        [ C.flex
        , C.flex_col
        , C.max_w_xs
        , C.px_3
        , C.w_screen

        --
        , C.sm__px_0
        ]
        [ UI.Kit.textFieldAlt
            [ attribute "autocapitalize" "off"
            , placeholder question.placeholder
            , Html.Events.onInput Input
            , value question.value
            ]
        , UI.Kit.button
            UI.Kit.Filled
            Authentication.Bypass
            (text "Continue")
        ]



-- SPEECH BUBBLE


speechBubble : Html msg -> Html msg
speechBubble contents =
    chunk
        [ C.absolute
        , C.antialiased
        , C.bg_background
        , C.border_b
        , C.border_transparent
        , C.font_semibold
        , C.italic
        , C.leading_snug
        , C.left_half
        , C.max_w_screen
        , C.minus_translate_x_half
        , C.px_4
        , C.py_2
        , C.rounded
        , C.text_center
        , C.text_sm
        , C.text_white
        , C.top_full
        , C.transform
        , C.whitespace_no_wrap

        -- Dark mode
        ------------
        , C.dark__bg_darkest_hour
        , C.dark__text_gray_600
        ]
        [ contents

        --
        , brick
            speechBubbleArrowStyles
            [ C.absolute
            , C.h_0
            , C.left_half
            , C.minus_translate_x_half
            , C.minus_translate_y_full
            , C.top_0
            , C.transform
            , C.w_0
            ]
            []
        ]



-- 🖼


speechBubbleArrowStyles : List (Html.Attribute msg)
speechBubbleArrowStyles =
    let
        color =
            Color.toCssString UI.Kit.colors.background
    in
    [ style "border-color" ("transparent transparent " ++ color ++ " transparent")
    , style "border-width" "0 6px 5px 6px"
    ]
