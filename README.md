# DevOps-тренировки в Яндексе
Домашнее задание для DevOps-тренировок в Яндексе, лекция "Облако. Кто виноват и что делать."

https://yandex.ru/yaintern/training/devops-training

## Утром пришло письмо
В нашей компании праздник - вчера купили перспективный стартап "CatGPT" - приложение, автоматически улучшающее фотографии путём дорисовывания фотореалистичных котиков. У ребят уже есть рабочий прототип, нужно как можно скорее развернуть его и открыть пользователям.

Сможешь всё сделать, как в лучших домах Лондона и Парижа? Если да, то это четыре динозаврика на ревью. Спасибо!

## Технические моменты
Для решение этой домашнего задания понадобится доступ к Яндекс Облаку. У зарегистрированных участников DevOps-тренировок есть возможность запросить грант в случае необходимости, для этого нужно заполнить форму: https://forms.yandex.ru/surveys/13482710.58cd805f71992dd086d6831888249bb90aa87cb3/

Не забудьте переключиться в folder в организации yandex-devops-training - грант покрывает потребление только в нём.

>[!WARNING]
>По завершении **_обязательно_** сделайте `terraform destroy`. Если не удалить созданные ресурсы - грант на облако будет расходоваться попусту, и его может не хватить для следующих домашних работ.

## Про приложение
По умолчанию приложение поднимает http-сервер на `:8080`

Readyness-проба для балансировщика висит на том же порту: `:8080/ping`

Приложение инструментировано метриками в формате Prometheus, которые по умолчанию можно получить на :9090/metrics.
Например, есть разбивка по дневным и ночным котикам:
```
# HELP enhanced_photo_count by cat type
# TYPE enhanced_photo_count counter
enhanced_photo_count{cat_type="diurnal"} 5
enhanced_photo_count{cat_type="nocturnal"} 1
```
Информацию о кодах ответов приложение отдает в метрике http_response_count
```
# HELP http_response_count by handler and code
# TYPE http_response_count counter
http_response_count{code="200",handler="/",method="post"} 1
http_response_count{code="200",handler="/ping",method="get"} 2
```

## Что нужно сделать.

* Прежде всего нужно залогиниться под своим аккаунтом и форкнуть себе репозиторий. В нём лежат исходники и terraform-инкструкция для разворачивания MVP 


* Написать Dockerfile. Приложение написано на go и собирается стандартным тулчейном:
    ```
    $ go mod download
    $ CGO_ENABLED=0 go build -o path/to/resulting/binary
    ```

    В качестве базового образа для сборки в docker рекомендуем использовать `golang:1.21`; в качестве базового образа для рантайма - `gcr.io/distroless/static-debian12:latest-amd64`

    https://go.dev/doc/tutorial/compile-install

    https://hub.docker.com/_/golang

    https://github.com/GoogleContainerTools/distroless

![Screenshot 2023-11-12 at 12 24 52](https://github.com/s1mba10/yandex-devops-training-2/assets/101098236/11c03720-e2d7-4a37-9a8b-0a40d19ae190)



* Опубликовать получившийся image в Yandex Container Registry (docker push)

    https://cloud.yandex.ru/docs/container-registry/


* Задача со звёздочкой: сделать автосборку с помощью Github CI

    https://docs.github.com/en/actions/publishing-packages/publishing-docker-images


* С помощью Terraform развернуть стенд с приложением:
    - сетевой балансировщик
    - две виртуальных машины под ним
  
![Screenshot 2023-11-12 at 12 21 44](https://github.com/s1mba10/yandex-devops-training-2/assets/101098236/f1257869-d2db-4a91-99b0-766d2466be68)

На каждой виртуальной машине должен быть запущен:
1) Контейнер с приложением. Тот самый контейнер, который собирался выше.
2) Unified-Agent. Unified-агент нужно будет настроить на получение метрик от приложения.

    https://cloud.yandex.ru/docs/monitoring/concepts/data-collection/unified-agent/configuration#metrics_pull_input

Важны момент: виртуальные машины обязательно использовать минимальных флейворов:
- Платформа Intel Cascade lake
- 2 vCPU
- Гарантированная доля vCPU 5%
- 1 ГБ RAM
- прерываемая

При решении можно комбинировать различные инструменты - как от Облака, так и сторонние (вроде salt или ansible). Но для полного погружения рекомендуем попробовать развернуть Instance Group на базе Container Optimized Image: https://cloud.yandex.ru/docs/cos/concepts/
https://cloud.yandex.ru/marketplace/products/yc/container-optimized-image

## После того, как стенд готов
* Построить в Yandex Monitoring графики, на которых для сервиса в целом можно будет посмотреть следующее:
    * Разбивку по типам нарисованных котивов (дневных и ночных)
    * Разбивку по кодам ответов, хендлерам и методам
https://cloud.yandex.ru/docs/monitoring/quickstart

![dashboard](https://github.com/s1mba10/yandex-devops-training-2/assets/101098236/1ab10ef4-c951-4cf7-8bfa-cc5cb8d5ba88)


* Задача со звёздочкой: дополнительно инструментировать приложение и доработать дашборд для того, чтобы получить графики времён обработки запросов в разрезе handler и method


* Выключить одну из виртуальных машин. Убедиться, что сервис продолжает жить и обслуживать запросы.


>[!WARNING]
>**_Обязательно_** сделать `terraform destroy`. Если не удалить созданные ресурсы - грант на облако будет расходоваться попусту, и его может не хватить для следующих домашних работ.

