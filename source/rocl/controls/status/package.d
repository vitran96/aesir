module rocl.controls.status;
import std, perfontain, perfontain.opengl, ro.grf, ro.conv.gui, rocl,
	rocl.game, rocl.status, rocl.controls, rocl.controls.status.equip,
	rocl.controls.status.stats, rocl.controls.status.bonuses, rocl.network.packets, rocl.gui.misc;

final:

class WinStatus
{
	void draw()
	{
		if (auto win = Window(MSG_CHARACTER, nk_vec2(410, 400)))
		{
			if (auto tree = Tree(MSG_EQUIPMENT))
				equip.draw;

			if (auto tree = Tree(MSG_STATS))
				stats.draw;
		}
	}

	EquipTab equip;
	StatsTab stats;
private:
	mixin NuklearBase;
}

struct EquipTab
{
	void draw()
	{
		auto slots = [
			Slot(EQP_HEAD_TOP, MSG_HEAD), Slot(EQP_HEAD_MID, MSG_HEAD),
			Slot(EQP_HEAD_LOW, MSG_HEAD), Slot(EQP_ARMOR, MSG_ARMOR),
			Slot(EQP_HAND_R, MSG_HAND_R), Slot(EQP_HAND_L, MSG_HAND_L),
			Slot(EQP_GARMENT, MSG_ROBE), Slot(EQP_SHOES, MSG_SHOES),
			Slot(EQP_ACC_R, MSG_ACC), Slot(EQP_ACC_L, MSG_ACC)
		];

		nk.layout_row_dynamic(24 + ctx.style.combo.content_padding.y * 2, 2);

		// _layout.styles ~= new Style(&ctx.style.combo.button_padding.y, 8); // make scroll arrow a bit smaller

		foreach (s; slots)
		{
			auto items = itemsForSlot(s.mask);
			auto idx = items.countUntil!(a => !!(a.equip2 & s.mask));

			if (idx >= 0) // https://issues.dlang.org/show_bug.cgi?id=21586
			{
				auto m = items[idx];
				auto tex = RO.gui.iconCache.get(m);

				if (auto combo = Combo(m.data.name, tex))
					processItems(s, combo, items, m);
			}
			else
			{
				if (auto combo = Combo(s.name))
					processItems(s, combo, items, null);
			}
		}
	}

	void processItems(T)(ref Slot s, ref T combo, Item[] items, Item eq) // TODO: REMOVE OVERLOAD
	{
		nk.layout_row_dynamic(combo.height, 1);

		if (combo.item(s.name) && eq)
			eq.action;

		foreach (m; items)
		{
			if (m is eq)
				continue;

			auto tex = RO.gui.iconCache.get(m);

			if (combo.item(m.data.name, tex))
				m.action;
		}
	}

private:
	mixin NuklearBase;

	struct Slot
	{
		uint mask;
		string name;
	}

	auto itemsForSlot(uint mask)
	{
		return RO.status.items.get(a => !!((a.equip2 ? a.equip2 : a.equip) & mask));
	}
}

struct StatsTab
{
	void draw()
	{
		string[][] params;

		auto fmt = `%u + %u`;
		auto points = param(SP_STATUSPOINT);

		params ~= [`ATK`, format(fmt, param(SP_ATK1), param(SP_ATK2))];
		params ~= [`DEF`, format(fmt, param(SP_DEF1), param(SP_DEF2))];

		params ~= [`MATK`, format(fmt, param(SP_MATK1), param(SP_MATK2))];
		params ~= [`MDEF`, format(fmt, param(SP_MDEF1), param(SP_MDEF2))];

		params ~= [`HIT`, param(SP_HIT).to!string];
		params ~= [`FLEE`, format(fmt, param(SP_FLEE1), param(SP_FLEE2))];

		params ~= [`CRIT`, param(SP_CRITICAL).to!string];
		params ~= [`ASPD`, (cast(uint)(200 - param(SP_ASPD) / 10f)).to!string];

		params ~= [MSG_SPEED, param(SP_SPEED).to!string];
		params ~= [MSG_STAT_POINTS, points.to!string];

		foreach (i, st; Stats)
		{
			auto v = &RO.status.stats[i];
			auto text = format(`%s: %s`, st, v.base);

			if (i == 0)
				makeLayout(true);
			else if (i == 4)
				makeLayout(false);

			if (v.needs)
			{
				if (nk.isWidgetHovered)
					nk.tooltip(format(MSG_STAT_COSTS, v.needs));

				if (points >= v.needs)
				{
					if (nk.button(text, NK_TEXT_LEFT, NK_SYMBOL_TRIANGLE_RIGHT))
					{
					}
				}
				else
					goto no_up;
			}
			else
			{
			no_up:
				nk.label(text, NK_TEXT_CENTERED);
			}
			nk.label(`+ ` ~ v.bonus.to!string);

			if (i >= 4)
			{
				nk.label(params[i + 4].front);
				nk.label(params[i + 4].back);
			}
			else
			{
				nk.label(params[i * 2].front);
				nk.label(params[i * 2].back);
				nk.label(params[i * 2 + 1].front);
				nk.label(params[i * 2 + 1].back);
			}
		}
	}

private:
	mixin NuklearBase;

	void makeLayout(bool extra)
	{
		const w = 30;

		with (LayoutRowTemplate(0))
		{
			foreach (i; 0 .. extra ? 3 : 2)
			{
				if (i)
					dynamic();
				else
					static_(120);

				static_(i ? w * 2 : w);
			}
		}
	}

	static param(ushort idx)
	{
		return RO.status.param(idx).value;
	}

	static immutable Stats = [`STR`, `AGI`, `VIT`, `INT`, `DEX`, `LUK`];
}
