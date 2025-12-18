--- STEAMODDED HEADER
--- MOD_NAME: Playtime!
--- MOD_ID: playtime
--- MOD_AUTHOR: [Gaffle]
--- MOD_DESCRIPTION: Placeholder~
--- PREFIX: playtime
--- VERSION: 0.0.0 BETA
--- BADGE_COLOUR: ffa1d4
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
            'Gains {C:attention}+1{} retrigger after each {C:attention}Blind{}.',
            ' ',
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
                    message = "Flattened!",
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
    cost = 12,

    config = {
        extra = {
            hands_played = 0,
            money_per_cycle = 10,
            hands_per_cycle = 2
        }
    },

    loc_txt = {
        name = 'Literal Pan',
        text = {
            '{C:red}Destroys{} a random card in hand,',
            'creates a random Joker.',
            ' ',
            'If there is no room for a new Joker,',
            'Earns {C:money}$#1#{} every {C:attention}#2#{} hands.',
            '{C:inactive}(#3#/#2# hands played){}',
            '',
            '{C:inactive}(Must Have Room)'
        }
    },

    loc_vars = function(self, info_queue, center)
        -- Add credits info box
        info_queue[#info_queue+1] = {
            set = 'Other',
            key = 'playtime_pan_credits'
        }
        
        return {vars = {
            center.ability.extra.money_per_cycle or 10,
            center.ability.extra.hands_per_cycle or 2,
            center.ability.extra.hands_played or 0
        }}
    end,

    calculate = function(self, card, context)
        -- Initialize extra fields if they don't exist
        if not card.ability.extra.hands_played then
            card.ability.extra.hands_played = 0
        end
        if not card.ability.extra.money_per_cycle then
            card.ability.extra.money_per_cycle = 10
        end
        if not card.ability.extra.hands_per_cycle then
            card.ability.extra.hands_per_cycle = 2
        end

        -- After playing a hand
        if context.after and not context.blueprint then
            -- Check if there's room for a new joker
            local has_room = #G.jokers.cards < G.jokers.config.card_limit
            
            if has_room and #G.hand.cards > 0 then
                -- Delete a random card from hand if any exist
                local card_to_delete = G.hand.cards[math.random(#G.hand.cards)]
                
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
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
                    trigger = 'before',
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
            else
                -- No room for jokers -  destroys hand & earn money instead
                -- Increment hand counter
                local has_room = #G.jokers.cards < G.jokers.config.card_limit
                
                local card_to_delete = G.hand.cards[math.random(#G.hand.cards)]
                
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.1,
                    blockable = false,
                    func = function()
                        play_sound('tarot1')
                        card_to_delete:juice_up(0.3, 0.4)
                        card_to_delete:start_dissolve()
                        return true
                    end
                }))

                
                card.ability.extra.hands_played = card.ability.extra.hands_played + 1

                -- Check if we've reached the cycle

                if card.ability.extra.hands_played >= card.ability.extra.hands_per_cycle then
                    -- Reset counter
                    card.ability.extra.hands_played = 0
                    
                    -- Give money
                    ease_dollars(card.ability.extra.money_per_cycle)
                    
                    card_eval_status_text(card, 'dollars', card.ability.extra.money_per_cycle, nil, nil, {
                        message = localize('$') .. card.ability.extra.money_per_cycle,
                        colour = G.C.MONEY
                    })
                    
                    return {
                        message = "Pop!",
                        colour = G.C.MONEY
                    }
                else
                    return {
                        message = card.ability.extra.hands_played .. "/" .. card.ability.extra.hands_per_cycle,
                        colour = G.C.UI.TEXT_INACTIVE
                    }
                end
            end
        end
    end
}

--------------------------------------------------
-- Russian Roulette
--------------------------------------------------
SMODS.Joker{
    key = "russian_roulette",
    atlas = "Jokers",
    pos = {x = 0, y = 2},
    rarity = 3,
    cost = 20,

    config = {
        extra = {
            mult = 0
        }
    },

    loc_txt = {
        name = 'Russian Roulette',
        text = {
            'Before scoring, {C:attention}50/50{} chance:',
            'Gain {C:red}+5{} Mult or {C:red}Destroy{} a random card in hand',
            ' ',
            '{C:inactive}(Currently {C:red}+#1#{C:inactive} Mult){}'
        }
    },
    
    loc_vars = function(self, info_queue, center)
        -- Add credits info box
        info_queue[#info_queue+1] = {
            set = 'Other',
            key = 'playtime_russian_roulette_credits'
        }

        return {vars = {
            center.ability.extra and center.ability.extra.mult or 0
        }}
    end,

    calculate = function(self, card, context)
        -- Initialize extra fields if they don't exist
        if not card.ability.extra then
            card.ability.extra = {
                mult = 0
            }
        end

        -- Trigger BEFORE scoring
        if context.before and not context.blueprint then      
            -- 50/50 coin flip: add mult or destroy card
            if pseudorandom('russian_roulette') < 0.5 then
                -- Heads: Add +5 Mult - ONLY shake and show message here
                card.ability.extra.mult = card.ability.extra.mult + 5
            
                play_sound('generic1', 1.2, 0.7)

                return {
                    message = "+5 Mult!",
                    colour = G.C.RED,
                    card = card
                }
            else
                -- Tails: Destroy a random card from hand - NO shake or message on joker
                if #G.hand.cards > 0 then
                    local card_to_delete = G.hand.cards[math.random(#G.hand.cards)]
                    card:juice_up(0.5, 0.5)
                    
                    play_sound('tarot1')
                    card_to_delete:juice_up(0.3, 0.4)
                    card_to_delete:start_dissolve()
                end
                -- Don't return anything - no message or shake for the joker
            end
        end
    

        -- Apply mult when scoring
        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                message = localize{type='variable', key='a_mult', vars={card.ability.extra.mult}},
                mult_mod = card.ability.extra.mult,
                colour = G.C.RED
            }
        end
    end
}
--------------------------------------------------
-- Custom Localization (Credits Boxes)
--------------------------------------------------
SMODS.current_mod.process_loc_text = function()
    G.localization.descriptions.Other = G.localization.descriptions.Other or {}
    
    G.localization.descriptions.Other.playtime_pan_credits = {
        name = "Credits",
        text = {
            "Concept by: {C:attention}@abbadabbers{}",
        }
    }

    G.localization.descriptions.Other.playtime_russian_roulette_credits = {
        name = "Credits",
        text = {
            "Concept by: {C:attention}@caserrr{}",
        }
    }
end
