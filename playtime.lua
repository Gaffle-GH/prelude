--- STEAMODDED HEADER
--- MOD_NAME: Playtime!
--- MOD_ID: playtime
--- MOD_AUTHOR: [Gaffle]
--- MOD_DESCRIPTION: Placeholder~
--- PREFIX: playtime
--- VERSION: 0.0.0 BETA
--- BADGE_COLOUR: #ffa1d4
-----------------------------------------------------
------------------- MOD CODE ------------------------


--------------------------------------------------
-- Register Custom Sound
--------------------------------------------------
SMODS.Sound{
    key = "playtime_dodgebonk",
    path = "dodgeball.ogg"
}



--------------------------------------------------
-- Load Joker Atlas
--------------------------------------------------
SMODS.Atlas{
    key = 'Jokers',
    path = 'Jokers.png',
    px = 71,
    py = 95
}


--------------------------------------------------
-- Dodgeball Joker (Will add delfation later)
--------------------------------------------------
SMODS.Joker{
    key = 'dodgeball',
    atlas = "Jokers",
    pos = {x = 0, y = 0}, 
    rarity = 2,
    cost = 6,

    config = {
        extra = {
            retriggers = 1,
            deflate_chance = 6
        }
    },

    loc_txt = {
        name = 'Dodgeball!',
        text = {
            'Retriggers all played cards {C:attention}#1#{} time(s)',
            'Gains {C:attention}+1{} retrigger after each {C:attention}Blind{}',
            '{C:green}#2# in #3#{} chance to {C:red}deflate{} after each hand'
        }
    },

    loc_vars = function(self, info_queue, center)
        return {vars = {
            center.ability.extra.retriggers or 1,
            G.GAME.probabilities.normal or 1,
            center.ability.extra.deflate_chance or 6
        }}
    end,


    --------------------------------------------------
    -- Joker Logic
    --------------------------------------------------
    calculate = function(self, card, context)

        -- Ensure fields exist
        if not card.ability.extra.retriggers then
            card.ability.extra.retriggers = 1
        end
        if not card.ability.extra.deflate_chance then
            card.ability.extra.deflate_chance = 6
        end


        --------------------------------------------------
        -- RETRIGGER LOGIC
        --------------------------------------------------
        if context.repetition and context.cardarea == G.play then
            return {
                message = "BONK!",
                repetitions = card.ability.extra.retriggers,
                card = card
            }
        end
        
        
        --------------------------------------------------
        -- AFTER ALL CARDS SCORED - Play sound
        --------------------------------------------------
        if context.after and not context.blueprint then
            -- Play sound after all retriggering is done
            play_sound("playtime_dodgebonk", 1.0, 0.6)
            return {
                message = "Done!"
            }
        end


        --------------------------------------------------
        -- AFTER ROUND → Increase retrigger count
        --------------------------------------------------
        if context.end_of_round and
           not context.blueprint and
           not context.repetition and
           not context.individual then

            card.ability.extra.retriggers = card.ability.extra.retriggers + 1
            
            card_eval_status_text(card, 'extra', nil, nil, nil, {
                message = localize('k_upgrade_ex'),
                colour = G.C.BLUE
            })

            return {
                message = "+1 Retrigger",
                colour = G.C.BLUE
            }
        end


        --------------------------------------------------
        -- AFTER HAND → Check for deflation
        --------------------------------------------------
        if context.after and not context.blueprint then
            local chance = card.ability.extra.deflate_chance

            if pseudorandom('dodgeball_deflate') < G.GAME.probabilities.normal / chance then
                
                -- Destroy card
                G.E_MANAGER:add_event(Event({
                    func = function()
                        play_sound('tarot1')
                        card.T.r = -0.2
                        card:juice_up(0.3, 0.4)

                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.3,
                            blockable = false,
                            func = function()
                                G.jokers:remove_card(card)
                                card:remove()
                                card = nil
                                return true
                            end
                        }))

                        return true
                    end
                }))

                return {
                    message = "Flattened.!",
                    colour = G.C.RED
                }
            end
        end
    end
}


--------------------------------------------------
-- (Literal) Pan Joker
--------------------------------------------------
SMODS.Joker{
    key = "literal_pan",
    atlas = "Jokers",
    pos = {x = 0, y = 1},
    rarity = 3,
    cost = 20,

    loc_txt = {
        name = 'Literal Pan',
        text = {
            '{C:red}Destroys{} a random card in hand,',
            'creates a random Joker',
            ' '
            'If there is no room for a new Joker,',
            '{C:red}Destroys{} a random card in hand,',
            ''
            '{C:inactive}(Must Have Room)'
        }
    },

    calculate = function(self, card, context)
        if context.after and not context.blueprint then
            -- Check if there's room for a new joker
            if #G.jokers.cards >= G.jokers.config.card_limit then
                return {
                    message = "No Room!",
                    colour = G.C.RED
                }
            end

            -- Delete a random card from hand if any exist
            if #G.hand.cards > 0 then
                local card_to_delete = G.hand.cards[math.random(#G.hand.cards)]
                
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.1,
                    blockable = false,
                    func = function()
                        play_sound('tarot1')
                        card_to_delete:juice_up(0.3, 0.4)
                        card_to_delete:start_dissolve()
                        return true
                    end
                }))

                -- Create a random joker with proper delay
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.4,
                    blockable = false,
                    func = function()
                        local new_joker = create_card('Joker', G.jokers, nil, nil, nil, nil, nil, 'literal_pan')
                        new_joker:add_to_deck()
                        G.jokers:emplace(new_joker)
                        new_joker:juice_up(0.3, 0.5)
                        play_sound('card1')
                        return true
                    end
                }))

                return {
                    message = "Pan'd!",
                    colour = G.C.ORANGE
                }
            end
        end
    end
}
--------------------------------------------------
-- Door?
--------------------------------------------------
SMODS.Joker{
    key = "door",
    atlas = "Jokers",
    pos = {x = 0, y = 2},
    rarity = 3,
    cost = 20,

    loc_txt = {
        name = 'Door',
        text = {
            'A strange door. Who knows where it leads?'
        }
    },

    calculate = function(self, card, context)
        return {}
    end
}
