module GameData
  class Trainer
    attr_reader :id
    attr_reader :id_number
    attr_reader :trainer_type
    attr_reader :real_name
    attr_reader :version
    attr_reader :items
    attr_reader :real_lose_text
    attr_reader :pokemon

    DATA = {}
    DATA_FILENAME = "trainers.dat"

    SCHEMA = {
      "Items"        => [:items,         "*e", :Item],
      "LoseText"     => [:lose_text,     "s"],
      "Pokemon"      => [:pokemon,       "ev", :Species],   # Species, level
      "Form"         => [:form,          "u"],
      "Name"         => [:name,          "s"],
      "Moves"        => [:moves,         "*e", :Move],
      "Ability"      => [:ability,       "s"],
      "AbilityIndex" => [:ability_index, "u"],
      "Item"         => [:item,          "e", :Item],
      "Gender"       => [:gender,        "e", { "M" => 0, "m" => 0, "Male" => 0, "male" => 0, "0" => 0,
                                                "F" => 1, "f" => 1, "Female" => 1, "female" => 1, "1" => 1 }],
      "Nature"       => [:nature,        "e", :Nature],
      "Roles"         => [:roles,          "*e", :Role],
      "IV"           => [:iv,            "uUUUUU"],
      "EV"           => [:ev,            "uUUUUU"],
      "Happiness"    => [:happiness,     "u"],
      "Shiny"        => [:shininess,     "b"],
      "SquareShiny"  => [:square_shiny,  "b"],
      "Shadow"       => [:shadowness,    "b"],
      "Ball"         => [:poke_ball,     "s"],
    }

    extend ClassMethods
    include InstanceMethods

    # @param tr_type [Symbol, String]
    # @param tr_name [String]
    # @param tr_version [Integer, nil]
    # @return [Boolean] whether the given other is defined as a self
    def self.exists?(tr_type, tr_name, tr_version = 0)
      validate tr_type => [Symbol, String]
      validate tr_name => [String]
      key = [tr_type.to_sym, tr_name, tr_version]
      return !self::DATA[key].nil?
    end

    # @param tr_type [Symbol, String]
    # @param tr_name [String]
    # @param tr_version [Integer, nil]
    # @return [self]
    def self.get(tr_type, tr_name, tr_version = 0)
      validate tr_type => [Symbol, String]
      validate tr_name => [String]
      key = [tr_type.to_sym, tr_name, tr_version]
      raise "Unknown trainer #{tr_type} #{tr_name} #{tr_version}." unless self::DATA.has_key?(key)
      return self::DATA[key]
    end

    # @param tr_type [Symbol, String]
    # @param tr_name [String]
    # @param tr_version [Integer, nil]
    # @return [self, nil]
    def self.try_get(tr_type, tr_name, tr_version = 0)
      validate tr_type => [Symbol, String]
      validate tr_name => [String]
      key = [tr_type.to_sym, tr_name, tr_version]
      return (self::DATA.has_key?(key)) ? self::DATA[key] : nil
    end

    def initialize(hash)
      @id             = hash[:id]
      @id_number      = hash[:id_number]
      @trainer_type   = hash[:trainer_type]
      @real_name      = hash[:name]         || "Unnamed"
      @version        = hash[:version]      || 0
      @items          = hash[:items]        || []
      @real_lose_text = hash[:lose_text]    || "..."
      @pokemon        = hash[:pokemon]      || []
      @pokemon.each do |pkmn|
        GameData::Stat.each_main do |s|
          pkmn[:iv][s.id] ||= 0 if pkmn[:iv]
          pkmn[:ev][s.id] ||= 0 if pkmn[:ev]
        end
      end
    end

    # @return [String] the translated name of this trainer
    def name
      return pbGetMessageFromHash(MessageTypes::TrainerNames, @real_name)
    end

    # @return [String] the translated in-battle lose message of this trainer
    def lose_text
      return pbGetMessageFromHash(MessageTypes::TrainerLoseText, @real_lose_text)
    end

    # Creates a battle-ready version of a trainer's data.
    # @return [Array] all information about a trainer in a usable form
    def to_trainer
      # Determine trainer's name
      tr_name = self.name
      Settings::RIVAL_NAMES.each do |rival|
        next if rival[0] != @trainer_type || !$game_variables[rival[1]].is_a?(String)
        tr_name = $game_variables[rival[1]]
        break
      end
      # Create trainer object
      trainer = NPCTrainer.new(tr_name, @trainer_type)
      trainer.id        = $Trainer.make_foreign_ID
      trainer.items     = @items.clone
      trainer.lose_text = self.lose_text
      # Create each Pokémon owned by the trainer
      randPkmn = Randomizer.trainers
      trainer_exclusions = $game_switches[906] ? nil : [:RIVAL1,:RIVAL2,:LEADER_Brock,:LEADER_Misty,:LEADER_Surge,:LEADER_Erika,:LEADER_Sabrina,:LEADER_Blaine,:LEADER_Winslow,:LEADER_Jackson,:OFFCORP,:DEFCORP,:PSYCORP,:ROCKETBOSS,:CHAMPION,:ARMYBOSS,:NAVYBOSS,:AIRFORCEBOSS,:GUARDBOSS,:CHANCELLOR,:DOJO_Luna,:DOJO_Apollo,:DOJO_Jasper,:DOJO_Maloki,:DOJO_Juliet,:DOJO_Adam,:DOJO_Wendy,:LEAGUE_Astrid,:LEAGUE_Winslow,:LEAGUE_Eugene,:LEAGUE_Armand,:LEAGUE_Winston,:LEAGUE_Vincent]
      if randPkmn.nil? || randPkmn == 0 || trainer_exclusions.include?(@trainer_type) || @version == 4 || @version == 6 || @version > 99
        @pokemon.each do |pkmn_data|
          species = GameData::Species.get(pkmn_data[:species]).species
          pkmn = Pokemon.new(species, pkmn_data[:level], trainer, false)
          trainer.party.push(pkmn)
          # Set Pokémon's properties if defined
          if pkmn_data[:form]
            pkmn.forced_form = pkmn_data[:form] if MultipleForms.hasFunction?(species, "getForm")
            pkmn.form_simple = pkmn_data[:form]
          end
          pkmn.item = pkmn_data[:item]
          if pkmn_data[:moves] && pkmn_data[:moves].length > 0
            pkmn_data[:moves].each { |move| pkmn.learn_move(move) }
          else
            pkmn.reset_moves
          end
          if !pkmn_data[:roles]
            pkmn.add_role(:NONE)
          else
            for i in pkmn_data[:roles]
              pkmn.add_role(i)
            end
          end
          pkmn.ability_index = pkmn_data[:ability_index]
          pkmn.ability = pkmn_data[:ability]
          pkmn.gender = pkmn_data[:gender] || ((trainer.male?) ? 0 : 1)
          pkmn.shiny = (pkmn_data[:shininess]) ? true : false
          pkmn.square_shiny = (pkmn_data[:square_shiny]) ? true : false
          if pkmn_data[:nature]
            pkmn.nature = pkmn_data[:nature]
          else
            nature = pkmn.species_data.id_number + GameData::TrainerType.get(trainer.trainer_type).id_number
            pkmn.nature = nature % (GameData::Nature::DATA.length / 2)
          end
          GameData::Stat.each_main do |s|
            if pkmn_data[:iv]
              pkmn.iv[s.id] = pkmn_data[:iv][s.id]
            else
              pkmn.iv[s.id] = [pkmn_data[:level] / 2, Pokemon::IV_STAT_LIMIT].min
            end
            if $game_switches[Settings::DISABLE_EVS]
              pkmn.ev[s.id] = 0
            else
              if pkmn_data[:ev]
                pkmn.ev[s.id] = pkmn_data[:ev][s.id]
              else
                pkmn.ev[s.id] = [pkmn_data[:level] * 3 / 2, Pokemon::EV_LIMIT / 6].min
              end
            end
          end
          pkmn.happiness = pkmn_data[:happiness] if pkmn_data[:happiness]
          pkmn.name = pkmn_data[:name] if pkmn_data[:name] && !pkmn_data[:name].empty?
          if pkmn_data[:shadowness]
            pkmn.makeShadow
            pkmn.update_shadow_moves(true)
            pkmn.shiny = false
          end
          pkmn.poke_ball = pkmn_data[:poke_ball] if pkmn_data[:poke_ball]
          pkmn.calc_stats
        end
      else
        idx = -1
        for i in randPkmn[:trainer]
          idx += 1
          break if i[0] == @trainer_type && i[1] == tr_name && i[2] == @version
        end
        randSpec = randPkmn[:pokemon][:species][idx]
        randLvl = randPkmn[:pokemon][:level][idx]
        lvl = -1
        randSpec.each do |pkmn_data|
          lvl += 1
          species = GameData::Species.get(pkmn_data).species
            pkmn = Pokemon.new(species, randLvl[lvl], trainer, false)
            trainer.party.push(pkmn)
            pkmn.reset_moves
            pkmn.calc_stats
        end
      end
      return trainer
    end
  end
end

#===============================================================================
# Deprecated methods
#===============================================================================
# @deprecated This alias is slated to be removed in v20.
def pbGetTrainerData(tr_type, tr_name, tr_version = 0)
  Deprecation.warn_method('pbGetTrainerData', 'v20', 'GameData::Trainer.get(tr_type, tr_name, tr_version)')
  return GameData::Trainer.get(tr_type, tr_name, tr_version)
end