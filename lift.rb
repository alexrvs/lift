class Lift
  MEN_LIMIT = 3      #предельная вместимость, чел.
  TOP_FLOOR = 9      #верхний этаж
  @@counter = 0      #счетчик пассажиров

  def initialize
    @men_inside = []   #массив пасажиров внутри лифта
    @men_outside = []  #массив ожидающих пассажиров, вызвавших лифт
    @current_floor = 1 #текущий этаж
    @direction = 0     #направление движения (+1 => наверх, -1 => вниз, 0 => лифт стоит)
  end

  def get_direction(from, to) #определение направления движения лифта
    (to - from)<=>0
  end

  def direction_name    #возвращает направление движения
    case @direction
      when -1 then 'вниз'
      when  0 then 'стоим на месте'
      when  1 then 'вверх'
    end
  end

  def request(at_floor, destination_floor) #обработка вызова лифта
    if at_floor<1 || at_floor>TOP_FLOOR
      puts "пассажир не может находиться на этаже #{at_floor}"
    elsif destination_floor<1 || destination_floor>TOP_FLOOR
      puts "пассажир не может запросить этаж #{destination_floor}"
    elsif at_floor==destination_floor
      puts "бессмысленно заказывать этаж, на котором уже находишься"
    else
      @men_outside << {:from => at_floor, :to => destination_floor, :id => @@counter += 1}
      puts "зарегистрирован вызов на этаже #{at_floor} (предполагается поездка на этаж #{destination_floor})"
    end
  end

  def coming(man) #обработка посадки в лифт
    @men_inside << man
    puts "пассажир #{man[:id]} вошел на этаже #{man[:from]} (предполагается поездка на этаж #{man[:to]})"
  end

  def outgoing(man) #обработка высадки из лифта
    puts "пассажир #{man[:id]} вышел на этаже #@current_floor"
  end

  def open_door #открытие дверей лифта на этаже
    puts "открыты двери на этаже #{@current_floor}"
    @men_inside.select{ |man| man[:to]==@current_floor }.each { |man| outgoing(@men_inside.delete(man)) }
    @direction = 0 if @men_inside.empty?
    @men_outside.select{ |man| man[:from]==@current_floor }.each do |man|
      if @men_inside.count < MEN_LIMIT
        if @direction==0 || @direction==get_direction(man[:from], man[:to])
          coming(@men_outside.delete(man))
          if @direction==0
            @direction = get_direction(man[:from], man[:to])
            puts "новый пассажир определил направление движения #{direction_name}"
          end
        else
          puts "Не удалось взять пассажира #{man[:id]} с этажа #{man[:from]}, т.к. он ожидает движения в противоположном направлении"
        end
      else
        puts "Не удалось взять пассажира #{man[:id]} с этажа #{man[:from]}, т.к. лифт переполнен"
      end
    end
  end

  def try_move #логика движения лифта
    last_state =  @direction

    if @direction==1
      if @men_inside.empty?
        #next_stop = @men_outside.map { |man| man[:from] }.select { |x| x > @current_floor }.min
        next_stop = @men_outside.first[:from] unless @men_outside.empty?
      else
        next_stop = @men_inside.map { |man| man[:to] }.select { |x| x > @current_floor }.min
      end
    elsif @direction==-1
      next_stop = (@men_inside.map { |man| man[:to] } | @men_outside.map { |man| man[:from] } ).select { |x| x < @current_floor }.max
    else
      if @men_outside.empty?
        next_stop = nil
      else
        if @men_outside.first[:from] == @current_floor
          open_door
          next_stop = @men_inside.first[:to]
        else
          next_stop = @men_outside.first[:from]
        end
      end
    end

    unless next_stop.nil?
      @direction = get_direction(@current_floor, next_stop)
      @current_floor += @direction
      puts "лифт проследовал до этажа #{@current_floor}"
      if @men_inside.any? { |man| man[:to] == @current_floor } ||
          @direction < 1 && @men_outside.any? { |man| man[:from] == @current_floor} ||
          @men_inside.empty? && @direction == 1 && @men_outside.first[:from] == @current_floor
        open_door
      end
    else
      @direction = 0
      puts "лифт стоит на месте - нет вызовов или пассажиров внутри" if last_state != @direction && @men_outside.empty?
    end
  end
end

puts "Нажмите <Enter> для вызова лифта"
l = Lift.new
loop do
  begin
    STDIN.read_nonblock(1)
    puts "Вы вызвали лифт. Укажите через запятую с какого этажа на какой вы хотите проследовать"
    from, to = gets.chomp.split(',')
    l.request(from.to_i, to.to_i)
  rescue SystemCallError
  end
  l.try_move
  sleep(2)
end