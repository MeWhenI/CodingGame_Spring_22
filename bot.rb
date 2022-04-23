STDOUT.sync = true

TYPE_MONSTER = 0
TYPE_MY_HERO = 1
TYPE_OP_HERO = 2

MAP_WIDTH  = 17630
MAP_HEIGHT = 9000

class Entity
 attr_reader :id, :x, :y, :shield_life, :is_controlled, :health, :vx, :vy, :near_base, :threat_for, :coords

 def initialize(id, stats)
  @id = id
  @x, @y, @shield_life, @is_controlled, @health, @vx, @vy, @near_base, @threat_for = stats
  @coords = [@x, @y]
 end

 def sqdist(target_coords)
  return (@x - target_coords[0])**2 + (@y - target_coords[1])**2
 end
end

class AI
 
end

class Def
 def self.defensive_guy(threats)
  return -1 if threats.size == 0

  return threats.min_by{ _1.sqdist($my_base_coords) }.id
 end

 def self.defend(monster, hero)
  if monster.sqdist(hero.coords) < 1280**2 && monster.shield_life == 0 && monster.sqdist($my_base_coords) < 2222 **2 && $mana >= 10
   $mana -= 10
   return "SPELL WIND #{$op_base_coords.join " "}"
  end

  return "MOVE #{monster.coords.join " "}"
 end

 def self.def_string(hero, monster_num, monster, base)
  s = monster_num == -1 ? "MOVE #{base.join " "}" : defend(monster, hero)
  s += " " + message()
  return s
 end
end

class Att
 def self.attack_guy(monsters)
  return -1 if monsters.size == 0

  return monsters.min_by { _1.sqdist($op_base_coords) }.id
 end

 def self.att_string(hero, monster_num, monster, base, op_heroes, monsters)
  if monsters.any?{ _1.sqdist($op_base_coords) < 800**2 }
    def_ops = op_heroes.filter{ _1.sqdist($op_base_coords) < 900**2}
    if def_ops.size > 0
     def_op = def_ops[0]
     if def_op.shield_life == 0 && $mana >= 20
      return "SPELL CONTROL #{def_op.id} #{$my_base_coords.join " "}"
     end
    end
  end
  s = monster_num == -1 ? "MOVE #{base.join " "}" : attack(monster, hero)
  s += " " + message()
  return s
 end

 def self.attack(monster, hero)
  wind = "SPELL WIND #{$op_base_coords.join " "}"
  shield = "SPELL SHIELD #{monster.id}"
  spell = wind
  spell = shield if monster.threat_for == 2 && rand(10) > 7 && monster.health >= 10
  if monster.sqdist(hero.coords) < 1280**2 && monster.shield_life == 0 && $mana >= 20
   $mana -= 10
   return spell
  end

  return "MOVE #{monster.coords.join " "}"
 end
end

def message
 4.times.map { ["ဪ", "꧅", "𒈙", "𒐫", "௵"].sample }.join
end

$jungler_dir = 1
$jungler_ofs = 0
def jungler_base(switch)
 ret = [$home_bases[1][0] + $jungler_ofs * switch, $home_bases[1][1] - $jungler_ofs * switch]
 $jungler_ofs += 1000 * $jungler_dir
 $jungler_dir = $jungler_ofs.abs >= 4000 ? -$jungler_dir : $jungler_dir
 return ret
end

$mana = 0

$my_base_coords = gets.split.collect &:to_i
$op_base_coords = [MAP_WIDTH - $my_base_coords[0], MAP_HEIGHT - $my_base_coords[1]]
$home_bases = [
  [$my_base_coords[0] == 0 ? 2000 : MAP_WIDTH - 2000, $my_base_coords[1] == 0 ? 2000 : MAP_HEIGHT - 2000],
  [$my_base_coords[0] == 0 ? 5000 : MAP_WIDTH - 5000, $my_base_coords[1] == 0 ? 5000 : MAP_HEIGHT - 5000],
  [$my_base_coords[0] != 0 ? 3000 : MAP_WIDTH - 3000, $my_base_coords[1] != 0 ? 3000 : MAP_HEIGHT - 3000]
]
$heroes_per_player = gets.to_i

$under_attack = false

loop {
 # Grab data
 my_health, my_mana = gets.split.collect &:to_i
 op_health, op_mana = gets.split.collect &:to_i
 $mana = my_mana

 my_heroes = []
 op_heroes = []
 monsters  = []
 gets.to_i.times {
  id, type, *stats = gets.split.collect &:to_i
  type == TYPE_MONSTER && monsters     << Entity.new(id, stats)
  type == TYPE_MY_HERO && my_heroes    << Entity.new(id, stats)
  type == TYPE_OP_HERO && op_heroes    << Entity.new(id, stats)
 }

 threats = monsters.filter { _1.threat_for == 1 }

 # Shmoov

 $under_attack |= op_heroes.any? { _1.sqdist($my_base_coords) < 5500 ** 2}

 # Defensive guy 0
 hero = my_heroes[0]
 target = Def.defensive_guy(threats.filter{ _1.sqdist($my_base_coords) < 6000**2 })
 puts Def.def_string(hero, target, monsters.find { _1.id == target }, $under_attack ? $home_bases[0] : jungler_base(-1))
 threats.delete(target) if threats.size > 1

 # Defensive guy 1
 hero = my_heroes[1]
 target = Def.defensive_guy(threats)
 puts Def.def_string(hero, target, monsters.find { _1.id == target }, jungler_base(1))

 # Attack guy 0
 hero = my_heroes[2]
 target = Att.attack_guy(monsters.filter { _1.shield_life == 0 && _1.sqdist($op_base_coords) < 7000**2 })
 puts Att.att_string(hero, target, monsters.find { _1.id == target }, $home_bases[2].map {_1 + 2000 - rand(4000)}, op_heroes, monsters)
}
