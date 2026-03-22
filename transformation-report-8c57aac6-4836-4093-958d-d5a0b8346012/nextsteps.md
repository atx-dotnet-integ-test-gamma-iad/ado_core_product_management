# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may not be fully compatible with the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify that behavior has not changed after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they indicate a regression introduced during migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific or platform-specific API calls that may cause issues when running on Linux or macOS:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Additionally, review any usage of `System.Windows`, `Microsoft.Win32`, or P/Invoke calls that may not be available cross-platform.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, environment variable access, and any configuration file loading, as these areas commonly differ across platforms.

## 7. Publish the Application

Once validation is complete, publish the application for the desired target platform. For a self-contained deployment targeting Linux x64, for example:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required assets are present before deploying to the target environment.