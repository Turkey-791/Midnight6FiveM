local Translations = {
    error = {
        ["invalid_job"] = "I dont think I work here...",
        ["invalid_items"] = "You do not have the correct items!",
        ["no_items"] = "You do not have any items!",
        ["wine_not_ready"] = "The wine is not ready yet...",
        ["too_far_to_sell"] = "You are too far from the delivery point",
        ["no_wine"] = "You do not have any wine to deliver",
        ["not_on_duty"] = "You must be on duty to do this",
        ["already_employed"] = "You are already employed here",
        ["too_far_to_apply"] = "You are too far from the entrance",
    },
    progress = {
        ["pick_grapes"] = "Picking Grapes ..",
        ["process_grapes"] = "Processing Grapes ..",
    },
    task = {
        ["start_task"] = "[E] To Start",
        ["load_ingrediants"] = "[E] Load Ingredients",
        ["wine_process"] = "[E] Start WineProcess",
        ["get_wine"] = "[E] Get Wine",
        ["make_grape_juice"] = "[E] Make Grape Juice",
        ["countdown"] = "Time Remaining %{time}s",
        ['cancel_task'] = "You have cancelled the task",
        ["sell_wine"] = "[G] Deliver Wine",
        ["apply_job"] = "[E] Apply For Job",
    },
    text = {
        ["start_shift"] = "You have started your shift at the vineyard!",
        ["end_shift"] = "Your shift at the vineyard has ended!",
        ["valid_zone"] = "Valid Zone!",
        ["invalid_zone"] = "Invalid Zone!",
        ["zone_entered"] = "%{zone} Zone Entered",
        ["zone_exited"] = "%{zone} Zone Exited",
        ["go_to_processing"] = "Head to the grape juice processing plant!",
    },
    success = {
        ["wine_sold"] = "You delivered the wine and received $%{value}",
        ["job_applied"] = "You are now employed at the vineyard!",
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
