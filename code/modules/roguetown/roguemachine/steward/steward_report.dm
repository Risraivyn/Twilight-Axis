/obj/item/paper/steward_report
	name = "steward's morning report"
	desc = "A crisply-stamped sheet summarising yesternight's dispatches to the Nerve Master. Meant for the Steward's eyes on rising."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "scroll"
	info = ""
	resistance_flags = FIRE_PROOF

/// Called at the end of SSeconomy.daily_tick. Prints a report onto the Nerve Master's tile.
/// `diff` is a /list produced by SSeconomy across the tick; see build_steward_report_body.
/proc/print_steward_report(list/diff)
	if(!diff)
		return
	var/obj/structure/roguemachine/steward/nm = SStreasury?.steward_machine
	if(!nm)
		return
	var/turf/drop = get_turf(nm)
	if(!drop)
		return
	var/obj/item/paper/steward_report/R = new(drop)
	R.info = build_steward_report_body(diff)
	R.update_icon()
	playsound(drop, 'sound/misc/coindispense.ogg', 40, FALSE, -1)

/proc/build_steward_report_body(list/diff)
	var/list/events_fired = diff["events_fired"]
	var/list/events_expired = diff["events_expired"]
	var/list/blockades_fired = diff["blockades_fired"]
	var/list/blockades_cleared = diff["blockades_cleared"]
	var/list/banditry_lines = diff["banditry_drain_lines"]
	var/banditry_total = diff["banditry_drain_total"] || 0
	var/banditry_burned = diff["banditry_drain_burned"] || 0
	var/banditry_debt_accrued = diff["banditry_drain_accrued_debt"] || 0
	var/orders_rolled = diff["orders_rolled"] || 0
	var/urgent_rolled = diff["urgent_rolled"] || 0
	var/day = diff["day"] || GLOB.dayspassed

	var/body = "<center><b>УТРЕННИЙ ОТЧЕТ СТЮАРДА</b></center><br>"
	body += "<center><i>Дае [day]</i></center><br><hr>"

	if(length(blockades_fired))
		body += "<b>Новые блокады:</b><br>"
		for(var/line in blockades_fired)
			body += "&nbsp;&nbsp;- [line]<br>"
		body += "<br>"
	if(length(blockades_cleared))
		body += "<b>Блокады сняты:</b><br>"
		for(var/line in blockades_cleared)
			body += "&nbsp;&nbsp;- [line]<br>"
		body += "<br>"
	if(length(events_fired))
		body += "<b>Новые экономические события:</b><br>"
		for(var/line in events_fired)
			body += "&nbsp;&nbsp;- [line]<br>"
		body += "<br>"
	if(length(events_expired))
		body += "<b>Ситуация нормализовалась:</b><br>"
		for(var/line in events_expired)
			body += "&nbsp;&nbsp;- [line]<br>"
		body += "<br>"
	if(banditry_total > 0)
		body += "<b>Финансовые потери от бандитизма:</b> <font color='#c44'>-[banditry_total]m</font><br>"
		for(var/line in banditry_lines)
			body += "&nbsp;&nbsp;- [line]<br>"
		if(banditry_debt_accrued > 0)
			body += "<i>Treasury could not absorb the full hit. <font color='#c44'>[banditry_debt_accrued]m</font> accrued as banditry debt: future inflow shall be skimmed against it until paid. ([banditry_burned]m drawn from purse, [banditry_debt_accrued]m owed.)</i><br>"
		body += "<br>"
	if(orders_rolled)
		body += "<b>Торговые заказы, выставленные этим утром:</b> [orders_rolled]"
		if(urgent_rolled)
			body += " ([urgent_rolled] urgent)"
		body += "<br><br>"
	if(!length(blockades_fired) && !length(blockades_cleared) && !length(events_fired) && !length(events_expired) && !orders_rolled && banditry_total <= 0)
		body += "<i>На дорогах спокойно. За ночь ни один караван не был потревожен.</i><br>"

	body += "<hr><center><i>Обратитесь к Книге Контрактов, чтобы подготовить ответные меры.</i></center>"
	return body
