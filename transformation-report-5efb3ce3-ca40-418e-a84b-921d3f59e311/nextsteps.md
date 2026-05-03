# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Removed or Changed APIs

Even with a clean build, some APIs behave differently across .NET versions. Review the following areas manually:

- **Database/ADO.NET usage**: Since the project is named `AdoCore`, verify that all `System.Data` and ADO.NET calls (e.g., `SqlConnection`, `DataAdapter`, `DataSet`) behave as expected on the new runtime.
- **Configuration**: If the project previously used `System.Configuration.ConfigurationManager`, confirm the `Microsoft.Extensions.Configuration` migration is complete or that the `System.Configuration.ConfigurationManager` NuGet package has been added.
- **Platform-specific APIs**: Check for any Windows-only APIs (e.g., registry access, COM interop) that may not function on Linux or macOS if cross-platform support is required.

## 5. Review NuGet Package Versions

Open the `.csproj` file and inspect all `<PackageReference>` entries. Ensure all packages are compatible with the target framework. You can check compatibility on [NuGet.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update any outdated packages as needed:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Run the Application

Execute the application directly to validate runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test all primary workflows, particularly any database connectivity or data access logic given the ADO-focused nature of the project.

## 7. Publish the Application

Once validation is complete, publish the application for the target environment.

For a self-contained deployment:

```bash
dotnet publish AdoCore.csproj --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish AdoCore.csproj --configuration Release --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your target environment. A full list of runtime identifiers is available in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

## 8. Validate the Published Output

Navigate to the publish output directory and run the application to confirm the published build functions correctly before deploying to the target environment.

```bash
cd ./publish
dotnet AdoCore.dll
```

Or, if published as a self-contained executable:

```bash
./AdoCore
```