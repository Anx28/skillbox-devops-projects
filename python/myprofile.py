def main():
    """
    Главная функция приложения MyProfile для предпринимателей
    """
    # Переменные для хранения личной информации
    personal_info = {
        'name': '',
        'age': 0,
        'phone': '',
        'email': '',
        'postal_index': '',
        'postal_address': '',
        'additional_info': ''
    }
    
    # Переменные для хранения информации о предпринимателе
    business_info = {
        'ogrnip': '',
        'inn': '',
        'bank_account': '',
        'bank_name': '',
        'bik': '',
        'correspondent_account': ''
    }
    
    while True:
        print("\n---ГЛАВНОЕ МЕНЮ")
        print("1 - Ввести или обновить информацию")
        print("2 - Вывести информацию") 
        print("0 - Завершить работу")
        
        choice = input("Введите номер пункта меню: ")
        
        if choice == '0':
            print("Работа приложения завершена. До свидания!")
            break
        elif choice == '1':
            input_or_update_info(personal_info, business_info)
        elif choice == '2':
            output_info(personal_info, business_info)
        else:
            print("Введён некорректный пункт меню")


def input_or_update_info(personal_info, business_info):
    """
    Функция для ввода или обновления информации
    """
    while True:
        print("\n---ВВЕСТИ ИЛИ ОБНОВИТЬ ИНФОРМАЦИЮ")
        print("1 - Личная информация")
        print("2 - Информация о предпринимателе")
        print("0 - Назад")
        
        choice = input("Введите номер пункта меню: ")
        
        if choice == '0':
            break
        elif choice == '1':
            input_personal_info(personal_info)
        elif choice == '2':
            input_business_info(business_info)
        else:
            print("Введён некорректный пункт меню")


def input_personal_info(personal_info):
    """
    Функция для ввода личной информации
    """
    print("\n---ВВОД ЛИЧНОЙ ИНФОРМАЦИИ")
    
    # Ввод имени
    personal_info['name'] = input("Введите имя: ")
    
    # Ввод возраста с проверкой
    while True:
        try:
            age = int(input("Введите возраст: "))
            if age >= 0:
                personal_info['age'] = age
                break
            else:
                print("Возраст должен быть неотрицательным числом. Попробуйте снова.")
        except ValueError:
            print("Возраст должен быть целым числом. Попробуйте снова.")
    
    # Ввод телефона
    personal_info['phone'] = input("Введите номер телефона (+70000000000): ")
    
    # Ввод email
    personal_info['email'] = input("Введите адрес электронной почты: ")
    
    # Ввод почтового индекса (сохраняем только цифры)
    postal_index_input = input("Введите почтовый индекс: ")
    personal_info['postal_index'] = ''.join(filter(str.isdigit, postal_index_input))
    
    # Ввод почтового адреса
    personal_info['postal_address'] = input("Введите почтовый адрес (без индекса): ")
    
    # Ввод дополнительной информации
    personal_info['additional_info'] = input("Введите дополнительную информацию: ")
    
    print("Личная информация успешно сохранена!")


def input_business_info(business_info):
    """
    Функция для ввода информации о предпринимателе
    """
    print("\n---ВВОД ИНФОРМАЦИИ О ПРЕДПРИНИМАТЕЛЕ")
    
    # Ввод ОГРНИП с проверкой на 15 цифр
    while True:
        try:
            ogrnip_input = input("Введите ОГРНИП: ")
            if len(ogrnip_input) == 15 and ogrnip_input.isdigit():
                business_info['ogrnip'] = ogrnip_input
                break
            else:
                print("ОГРНИП должен содержать ровно 15 цифр. Попробуйте снова.")
        except ValueError:
            print("ОГРНИП должен содержать только цифры. Попробуйте снова.")
    
    # Ввод ИНН
    while True:
        try:
            inn = int(input("Введите ИНН: "))
            business_info['inn'] = inn
            break
        except ValueError:
            print("ИНН должен быть целым числом. Попробуйте снова.")
    
    # Ввод расчетного счета с проверкой на 20 цифр
    while True:
        try:
            bank_account_input = input("Введите расчетный счет: ")
            if len(bank_account_input) == 20 and bank_account_input.isdigit():
                business_info['bank_account'] = bank_account_input
                break
            else:
                print("Расчетный счет должен содержать ровно 20 цифр. Попробуйте снова.")
        except ValueError:
            print("Расчетный счет должен содержать только цифры. Попробуйте снова.")
    
    # Ввод названия банка
    business_info['bank_name'] = input("Введите название банка: ")
    
    # Ввод БИК
    while True:
        try:
            bik = int(input("Введите БИК: "))
            business_info['bik'] = bik
            break
        except ValueError:
            print("БИК должен быть целым числом. Попробуйте снова.")
    
    # Ввод корреспондентского счета
    business_info['correspondent_account'] = input("Введите корреспондентский счет: ")
    
    print("Информация о предпринимателе успешно сохранена!")


def output_info(personal_info, business_info):
    """
    Функция для вывода информации
    """
    while True:
        print("\n---ВЫВОД ИНФОРМАЦИИ")
        print("1 - Личная информация")
        print("2 - Вся информация")
        print("0 - Назад")
        
        choice = input("Введите номер пункта меню: ")
        
        if choice == '0':
            break
        elif choice == '1':
            output_personal_info(personal_info)
        elif choice == '2':
            output_all_info(personal_info, business_info)
        else:
            print("Введён некорректный пункт меню")


def output_personal_info(personal_info):
    """
    Функция для вывода личной информации
    """
    print("\n---ЛИЧНАЯ ИНФОРМАЦИЯ")
    
    if personal_info['name']:
        print(f"Имя: {personal_info['name']}")
    else:
        print("Имя: не указано")
    
    if personal_info['age'] > 0:
        print(f"Возраст: {personal_info['age']}")
    else:
        print("Возраст: не указан")
    
    if personal_info['phone']:
        print(f"Телефон: {personal_info['phone']}")
    else:
        print("Телефон: не указан")
    
    if personal_info['email']:
        print(f"Электронная почта: {personal_info['email']}")
    else:
        print("Электронная почта: не указана")
    
    if personal_info['postal_index']:
        print(f"Индекс: {personal_info['postal_index']}")
    else:
        print("Индекс: не указан")
    
    if personal_info['postal_address']:
        print(f"Почтовый адрес: {personal_info['postal_address']}")
    else:
        print("Почтовый адрес: не указан")
    
    if personal_info['additional_info']:
        print(f"Дополнительная информация: {personal_info['additional_info']}")
    else:
        print("Дополнительная информация: не указана")


def output_all_info(personal_info, business_info):
    """
    Функция для вывода всей информации
    """
    # Вывод личной информации
    output_personal_info(personal_info)
    
    print("\n---ИНФОРМАЦИЯ О ПРЕДПРИНИМАТЕЛЕ")
    
    if business_info['ogrnip']:
        print(f"ОГРНИП: {business_info['ogrnip']}")
    else:
        print("ОГРНИП: не указан")
    
    if business_info['inn']:
        print(f"ИНН: {business_info['inn']}")
    else:
        print("ИНН: не указан")
    
    if business_info['bank_account']:
        print(f"Расчетный счет: {business_info['bank_account']}")
    else:
        print("Расчетный счет: не указан")
    
    if business_info['bank_name']:
        print(f"Название банка: {business_info['bank_name']}")
    else:
        print("Название банка: не указано")
    
    if business_info['bik']:
        print(f"БИК: {business_info['bik']}")
    else:
        print("БИК: не указан")
    
    if business_info['correspondent_account']:
        print(f"Корреспондентский счет: {business_info['correspondent_account']}")
    else:
        print("Корреспондентский счет: не указан")


if __name__ == "__main__":
    print("Приложение MyProfile для предпринимателей")
    print("Сохраняй информацию о себе и выводи ее в разных форматах")
    main()
