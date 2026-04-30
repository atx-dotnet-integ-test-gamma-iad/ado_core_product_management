# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were silently ignored during transformation.

## 3. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update any outdated packages that have stable releases compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Data` and ADO.NET provider usage (relevant given the `AdoCore` project name)
- Database connection strings and driver compatibility (e.g., ensure the correct NuGet package for your database driver is referenced, such as `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient`)
- `ConfigurationManager` usage — replace with `Microsoft.Extensions.Configuration` if needed
- Any Windows-specific registry or COM interop calls

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.